locals {
  tags = merge({
    workload    = "agent-factory"
    environment = var.environment
    managed_by  = "terraform"
  }, var.tags)
}

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name             = "rg-agentfactory-${var.environment}"
  location         = var.location
  tags             = local.tags
  enable_telemetry = false
}

# R1 governed gateway is deployed by stacks/spoke-gateway (the adopted accelerator).
# Read its outputs so the harness can wire the MCP tool + PDP into the gateway and so
# harness outputs surface the full picture. Deploy spoke-gateway before spoke-harness.
#
# Off by default: the harness stands up on Container Apps only (MCP tool + PDP + ACR +
# Lighthouse) with no large-compute accelerator. Set enable_gateway_integration = true
# only in a spoke where the accelerator (App Service / APIM / Cosmos / Event Hub / private
# endpoints) is already deployed, to wire the harness into it.
data "terraform_remote_state" "gateway" {
  count   = var.enable_gateway_integration ? 1 : 0
  backend = "azurerm"
  config = {
    use_oidc             = true
    resource_group_name  = var.gateway_state_resource_group_name
    storage_account_name = var.gateway_state_storage_account_name
    container_name       = var.gateway_state_container_name
    key                  = var.gateway_state_key
  }
}

# A-4.1 Telemetry sink: Log Analytics workspace for the harness. The MCP tool and the
# policy engine (PDP) send their Container Apps logs here via the managed environment, and
# the hub reads it through the Lighthouse delegation. Without this a lite spoke has no
# queryable sink, so the hub rollup would be empty even with Lighthouse in place.
module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                = "log-agentfactory-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.tags
  enable_telemetry    = false

  # Allow the hub to query this sink over Lighthouse, and allow the Container Apps
  # environment to ingest console logs into it. The AVM module defaults both access
  # modes off (SecuredByPerimeter), which blocks cross-tenant reads AND silently drops
  # the spoke's own container logs.
  log_analytics_workspace_internet_query_enabled     = "true"
  log_analytics_workspace_internet_ingestion_enabled = "true"
}

# R2 - Container App Environment that hosts the MCP tool
module "mcp_env" {
  source  = "Azure/avm-res-app-managedenvironment/azurerm"
  version = "0.5.0"

  name                = "cae-agentfactory-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  zone_redundant      = false
  enable_telemetry    = false
  tags                = local.tags

  # Route all Container Apps logs (MCP tool + PDP) to the harness workspace above so the
  # hub can read spoke signals over Lighthouse.
  log_analytics_workspace = {
    resource_id = module.log_analytics.resource_id
  }
}

# A-2.1 - immutable artifact repository (Premium) that will hold the MCP tool image.
# Name must be globally unique and alphanumeric only; add a suffix before a real deploy.
module "acr" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "0.8.0"

  name                     = "acragentfac${var.environment}"
  location                 = var.location
  resource_group_name      = module.resource_group.name
  sku                      = var.acr_sku
  zone_redundancy_enabled  = false
  retention_policy_in_days = 7
  tags                     = local.tags
  enable_telemetry         = false
}

# A-1.3 Policy Engine (PDP): OPA served as a Container App; the gateway PEP calls it.
module "policy_engine" {
  source = "../../modules/policy-engine"

  name                                  = "ca-pdp-${var.environment}"
  resource_group_name                   = module.resource_group.name
  location                              = var.location
  container_app_environment_resource_id = module.mcp_env.resource_id
  authz_rego                            = file("${path.module}/../../policy/authz.rego")
  min_replicas                          = var.keep_warm ? 1 : 0
  tags                                  = local.tags
}

# X-3 Event Bus is provided by the adopted accelerator (spoke-gateway eventhub_namespace).

# Azure Lighthouse: delegate this spoke to the hub tenant for central telemetry/cost rollup.
# Off by default; a spoke enables it with the hub tenant id + hub principal object id.
module "lighthouse" {
  count  = var.enable_lighthouse ? 1 : 0
  source = "../../modules/lighthouse-delegation"

  subscription_scope = "/subscriptions/${var.subscription_id}"
  managing_tenant_id = var.hub_tenant_id

  authorizations = [
    # Reader
    { principal_id = var.lighthouse_principal_id, role_definition_id = "acdd72a7-3385-48ef-bd42-f606fba81ae7", principal_display_name = var.lighthouse_principal_display_name },
    # Monitoring Reader
    { principal_id = var.lighthouse_principal_id, role_definition_id = "43d0d8ad-25c7-4714-9337-8ba259a9fe05", principal_display_name = var.lighthouse_principal_display_name }
  ]
}

# R2 - MCP tool. Placeholder image by default; set mcp_tool_image (and mcp_tool_target_port
# 8080 to match the governed-read Dockerfile) once that image is pushed to the spoke ACR.
module "mcp_tool" {
  source = "../../modules/mcp-tool"

  name                                  = "ca-mcp-${var.environment}"
  resource_group_name                   = module.resource_group.name
  location                              = var.location
  container_app_environment_resource_id = module.mcp_env.resource_id
  image                                 = var.mcp_tool_image
  target_port                           = var.mcp_tool_target_port
  registry_server                       = var.mcp_tool_registry_server
  env_vars                              = var.mcp_tool_env_vars
  secret_env_vars                       = var.mcp_tool_secret_env_vars
  min_replicas                          = var.keep_warm ? 1 : 0
  tags                                  = local.tags
}

# Let the MCP tool pull its image from the registry. Standalone (not in the ACR module)
# to keep the tool<->registry relationship acyclic, same pattern as apim_openai.
resource "azurerm_role_assignment" "mcp_acrpull" {
  scope                = module.acr.resource_id
  role_definition_name = "AcrPull"
  principal_id         = module.mcp_tool.identity_principal_id
}

# B-1.1 Agent Runtime backend (Option A): an Azure AI Foundry (AIServices) account with
# project management so this spoke can host an agent that reaches data ONLY through the
# governed MCP tool (B-1.2/B-1.3). Region may differ from the spoke to find model quota.
module "foundry" {
  count   = var.enable_foundry ? 1 : 0
  source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "0.11.1"

  name                          = "aif-agentfactory-${var.environment}"
  location                      = coalesce(var.foundry_location, var.location)
  parent_id                     = module.resource_group.resource_id
  kind                          = "AIServices"
  sku_name                      = "S0"
  custom_subdomain_name         = "aif-agentfactory-${var.environment}"
  allow_project_management      = true
  public_network_access_enabled = true
  local_auth_enabled            = true
  managed_identities            = { system_assigned = true }
  tags                          = local.tags
  enable_telemetry              = false

  cognitive_deployments = {
    (var.foundry_model) = {
      name = var.foundry_model
      model = {
        format  = "OpenAI"
        name    = var.foundry_model
        version = var.foundry_model_version
      }
      scale = {
        type     = "Standard"
        capacity = var.foundry_model_capacity
      }
    }
  }
}

# B-2.1 Guardrails: a standalone Content Safety account the agent/tool can call for
# input/output moderation (the model deployment also carries a default content filter).
module "content_safety" {
  count   = var.enable_foundry ? 1 : 0
  source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "0.11.1"

  name                          = "cs-agentfactory-${var.environment}"
  location                      = coalesce(var.foundry_location, var.location)
  parent_id                     = module.resource_group.resource_id
  kind                          = "ContentSafety"
  sku_name                      = "S0"
  custom_subdomain_name         = "cs-agentfactory-${var.environment}"
  public_network_access_enabled = true
  tags                          = local.tags
  enable_telemetry              = false
}

# A-2.2 capability catalog (API Center) is provided by the adopted accelerator.

# TODO R2: register the MCP tool as a governed backend/API in the accelerator's APIM
#      gateway (data.terraform_remote_state.gateway.outputs.apim_name) and implement the
#      classification-checked governed read against the synthetic Omni-style endpoint.
# TODO A-1.3/B-2.3: point the gateway PEP at the PDP (module.policy_engine.pdp_url) via an
#      APIM policy fragment, once the Aug 25 identity decision lands.
# TODO Step 3 (adopt-and-wrap): add the AGT module (ACS v5) for runtime policy +
#      tamper-evident audit alongside the OPA PDP (defense in depth).
