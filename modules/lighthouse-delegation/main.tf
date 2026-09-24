# Azure Lighthouse delegation (cross-tenant management). Deployed in THIS (spoke) subscription
# to delegate read access to the hub tenant, so telemetry and cost roll up centrally.
# No AVM module exists (registry checked 2026-08-23); thin AVM-style azapi wrapper.

resource "azapi_resource" "registration_definition" {
  type      = "Microsoft.ManagedServices/registrationDefinitions@2022-10-01"
  name      = var.registration_definition_id
  parent_id = var.subscription_scope

  body = {
    properties = {
      registrationDefinitionName = var.definition_name
      managedByTenantId          = var.managing_tenant_id
      authorizations = [
        for a in var.authorizations : {
          principalId            = a.principal_id
          roleDefinitionId       = a.role_definition_id
          principalIdDisplayName = a.principal_display_name
        }
      ]
    }
  }
}

resource "azapi_resource" "registration_assignment" {
  type      = "Microsoft.ManagedServices/registrationAssignments@2022-10-01"
  name      = var.registration_assignment_id
  parent_id = var.subscription_scope

  body = {
    properties = {
      registrationDefinitionId = azapi_resource.registration_definition.id
    }
  }
}
