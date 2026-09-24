# R2 - MCP tool (B-1.2 / B-1.3): least-privilege MCP server that hosts the governed read.
# Thin AVM-style wrapper over the AVM Container App module. Runs a placeholder image until the
# real MCP server (with the classification-checked governed read) is built; that read logic is
# blocked on the pilot SOP (due Aug 28).

locals {
  # Container Apps secret names must be lowercase alphanumeric with hyphens; env var names are
  # upper snake case, so map each secret env var to a compliant secret name.
  mcp_secret_names = { for env_name, _ in var.secret_env_vars : env_name => lower(replace(env_name, "_", "-")) }
}

module "containerapp" {
  source  = "Azure/avm-res-app-containerapp/azurerm"
  version = "0.9.0"

  name                                  = var.name
  resource_group_name                   = var.resource_group_name
  container_app_environment_resource_id = var.container_app_environment_resource_id
  location                              = var.location
  revision_mode                         = "Single"
  tags                                  = var.tags

  managed_identities = {
    system_assigned = true
  }

  secrets = { for env_name, val in var.secret_env_vars : local.mcp_secret_names[env_name] => {
    name  = local.mcp_secret_names[env_name]
    value = val
  } }

  template = {
    min_replicas = var.min_replicas
    containers = [{
      name   = "mcp"
      image  = var.image
      cpu    = 0.25
      memory = "0.5Gi"
      env = concat(
        [for env_name, val in var.env_vars : { name = env_name, value = val }],
        [for env_name, val in var.secret_env_vars : { name = env_name, secret_name = local.mcp_secret_names[env_name] }],
      )
    }]
  }

  ingress = {
    external_enabled = true
    target_port      = var.target_port
    traffic_weight = [{
      latest_revision = true
      percentage      = 100
    }]
  }

  # Private-registry pull: when the tool runs its own image from the spoke ACR (not the
  # public placeholder), authenticate with this app's system-assigned identity, which the
  # harness grants AcrPull. Null keeps the public placeholder path unauthenticated.
  registries = var.registry_server == null ? null : [{
    server   = var.registry_server
    identity = "System"
  }]
}
