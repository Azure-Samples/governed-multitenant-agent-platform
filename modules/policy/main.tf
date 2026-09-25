# Curated AI-platform guardrail initiative (audit-first). Groups built-in Azure Policy
# definitions that map to this governed agent platform's design:
# seal the model backends, require keyless + private access, keep telemetry flowing, and
# govern tags/locations. GUIDs verified against the live built-in catalogue (2026-09-17).
# Effects default to Audit (report, block nothing); raise auditEffect to Deny and
# configureEffect to Modify per tenant once findings are clean.

locals {
  builtin = "/providers/Microsoft.Authorization/policyDefinitions"

  # Audit-capable members: effect -> auditEffect.
  audit_members = [
    { ref = "cs-managed-identity", id = "fe3fd216-4f83-4fc1-8984-2bbec80a3418" },       # Cognitive Services accounts should use a managed identity
    { ref = "foundry-model-eligibility", id = "8791d062-ba96-4c34-b604-8538f7e30ca0" }, # Foundry model deployments should meet eligibility requirements
    { ref = "storage-no-shared-key", id = "8c6a50c6-9ffd-4ae7-986f-5fa6111f9a54" },     # Storage accounts should prevent shared key access
    { ref = "storage-secure-transfer", id = "404c3081-a854-4457-ae30-26a93ef643f9" },   # Secure transfer to storage accounts should be enabled
    { ref = "storage-min-tls", id = "fe83a0eb-a853-422d-aac2-1bffd182c5d0" },           # Storage accounts should have the specified minimum TLS version
    { ref = "storage-no-public", id = "4fa4b6c0-31ca-4c0d-b10d-24b96f62a751" },         # Storage account public access should be disallowed
    { ref = "kv-soft-delete", id = "1e66c121-a66a-4b1f-9b83-0fd99bf0fc2d" },            # Key vaults should have soft delete enabled
    { ref = "kv-rbac", id = "12d4fa5e-1f9f-4c21-97a9-b99b3c6611b5" },                   # Azure Key Vault should use RBAC permission model
    { ref = "kv-no-public", id = "405c5871-3e91-4644-8a63-58e19d68ff5b" },              # Azure Key Vault should disable public network access
    { ref = "search-no-public", id = "ee980b6d-0eca-4501-8d54-f6290fd512c3" },          # AI Search should disable public network access
    { ref = "search-no-local-auth", id = "6300012e-e9a4-4649-b41f-a85f5c43be91" },      # AI Search local auth disabled
    { ref = "aca-env-no-public", id = "d074ddf8-01a5-4b5e-a2b8-964aed452c0a" },         # Container Apps environment should disable public network access
    { ref = "aca-no-external", id = "783ea2a8-b8fd-46be-896a-9ae79643a0b1" },           # Container Apps should disable external network access
    { ref = "apim-vnet", id = "ef619a2c-cc4d-4d03-b2ba-8c94a834d85b" },                 # API Management services should use a virtual network
    { ref = "apim-no-direct-mgmt", id = "b741306c-968e-4b67-b916-5675e5c709f4" },       # API Management direct management endpoint should not be enabled
  ]

  # Remediation members (Cognitive Services): effect -> configureEffect (Disabled by default).
  configure_members = [
    { ref = "cs-disable-public", id = "47ba1dd7-28d9-4b07-a8d5-9813bed64e0c" },     # Configure Cognitive Services accounts to disable public network access
    { ref = "cs-disable-local-auth", id = "14de9e63-1b31-492e-a5a3-c3f7fd57f555" }, # Configure Cognitive Services accounts to disable local authentication methods
  ]

  members_audit = [for m in local.audit_members : {
    ref    = m.ref
    id     = "${local.builtin}/${m.id}"
    params = jsonencode({ effect = { value = "[parameters('auditEffect')]" } })
  }]

  members_configure = [for m in local.configure_members : {
    ref    = m.ref
    id     = "${local.builtin}/${m.id}"
    params = jsonencode({ effect = { value = "[parameters('configureEffect')]" } })
  }]

  member_locations = [{
    ref = "allowed-locations"
    id  = "${local.builtin}/e56962a6-4747-49cd-b67b-bf8b01975c4c" # Allowed locations
    params = jsonencode({
      effect                 = { value = "[parameters('auditEffect')]" }
      listOfAllowedLocations = { value = "[parameters('allowedLocations')]" }
    })
  }]

  # Diagnostics-to-hub is included only when a workspace is provided (logAnalytics is required).
  member_diagnostics = var.log_analytics_workspace_id == "" ? [] : [{
    ref = "kv-diagnostics-to-hub"
    id  = "${local.builtin}/bef3f64c-5290-43b7-85b0-9b254eef4c47" # Deploy Diagnostic Settings for Key Vault to Log Analytics workspace
    params = jsonencode({
      effect       = { value = "[parameters('diagnosticsEffect')]" }
      logAnalytics = { value = var.log_analytics_workspace_id }
    })
  }]

  member_models = var.enable_approved_models_policy ? [{
    ref = "foundry-approved-models"
    id  = "${local.builtin}/aafe3651-cb78-4f68-9f81-e7e41509110f" # Foundry model deployments should only use approved models
    params = jsonencode({
      effect            = { value = "[parameters('auditEffect')]" }
      allowedPublishers = { value = var.allowed_model_publishers }
      allowedAssetIds   = { value = [] }
    })
  }] : []

  members = concat(
    local.members_audit,
    local.members_configure,
    local.member_locations,
    local.member_diagnostics,
    local.member_models,
  )

  # Initiative parameters, assembled conditionally so none are left unused.
  params_base = {
    auditEffect = {
      type          = "String"
      allowedValues = ["Audit", "Deny", "Disabled"]
      defaultValue  = var.audit_effect
      metadata      = { displayName = "Audit effect", description = "Effect for audit-capable guardrails. Audit reports only; Deny blocks non-compliant creates." }
    }
    configureEffect = {
      type          = "String"
      allowedValues = ["Modify", "Disabled"]
      defaultValue  = var.configure_effect
      metadata      = { displayName = "Configure (remediation) effect", description = "Modify auto-seals Cognitive Services public access / local auth; Disabled leaves it inert (audit-first)." }
    }
    allowedLocations = {
      type         = "Array"
      defaultValue = var.allowed_locations
      metadata     = { displayName = "Allowed locations", description = "Regions resources may deploy to.", strongType = "location" }
    }
  }

  params_diag = var.log_analytics_workspace_id == "" ? {} : {
    diagnosticsEffect = {
      type          = "String"
      allowedValues = ["DeployIfNotExists", "Disabled"]
      defaultValue  = var.diagnostics_effect
      metadata      = { displayName = "Diagnostics effect", description = "DeployIfNotExists ships resource diagnostics to the hub workspace." }
    }
  }

  parameters = merge(local.params_base, local.params_diag)
}

resource "azurerm_policy_set_definition" "this" {
  name                = var.name
  policy_type         = "Custom"
  display_name        = var.display_name
  description         = var.description
  management_group_id = var.management_group_id
  parameters          = jsonencode(local.parameters)

  dynamic "policy_definition_reference" {
    for_each = local.members
    content {
      policy_definition_id = policy_definition_reference.value.id
      reference_id         = policy_definition_reference.value.ref
      parameter_values     = policy_definition_reference.value.params
    }
  }
}

# Audit-first assignment (opt-in). Scoped to one subscription; Azure Policy is per-tenant, so
# each federated tenant assigns its own copy. A system-assigned identity is attached so raising
# configureEffect / diagnosticsEffect to remediation later needs no reassignment.
resource "azurerm_subscription_policy_assignment" "this" {
  count = var.enable_assignment ? 1 : 0

  name                 = var.assignment_name
  subscription_id      = "/subscriptions/${var.assignment_subscription_id}"
  policy_definition_id = azurerm_policy_set_definition.this.id
  display_name         = var.display_name
  description          = var.description
  enforce              = var.enforce
  location             = var.assignment_location

  identity {
    type = "SystemAssigned"
  }
}
