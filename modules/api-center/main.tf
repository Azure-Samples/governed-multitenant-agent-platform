# A-2.2 Capability Catalog & Discovery (Azure API Center).
# No published AVM module exists yet (registry checked 2026-08-23). This is a thin
# AVM-style azapi wrapper (standard name/location/tags/interfaces). Swap to the AVM
# module when it ships.

resource "azapi_resource" "service" {
  type      = "Microsoft.ApiCenter/services@2024-03-01"
  name      = var.name
  location  = var.location
  parent_id = var.resource_group_id
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {}
  }
}

# Register the MCP tool so the governed tool is discoverable in the catalog. Uses the
# 'default' workspace API Center provisions automatically.
resource "azapi_resource" "mcp_api" {
  count     = var.register_mcp_api ? 1 : 0
  type      = "Microsoft.ApiCenter/services/workspaces/apis@2024-03-01"
  name      = var.mcp_api_name
  parent_id = "${azapi_resource.service.id}/workspaces/default"

  body = {
    properties = {
      title   = var.mcp_api_title
      kind    = "rest"
      summary = var.mcp_api_summary
    }
  }
}
