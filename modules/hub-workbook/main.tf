# R4 hub dashboard: Azure Monitor Workbook (cross-tenant governance + ROI).
# Content is authored in hub-governance-workbook.json.tftpl (single source of truth) and rendered
# via templatefile from local.spokes (see locals.tf) so onboarding a BU is one config entry. No AVM
# module exists for workbooks (registry checked 2026-08-23); thin AVM-style azapi wrapper. The tiles
# read spoke telemetry cross-workspace via workspace('...') over Lighthouse and live resource state
# via Azure Resource Graph, so nothing is copied to the hub.
resource "azapi_resource" "workbook" {
  type      = "Microsoft.Insights/workbooks@2022-04-01"
  name      = var.workbook_id
  location  = var.location
  parent_id = var.resource_group_id
  tags      = var.tags

  body = {
    kind = "shared"
    properties = {
      displayName = var.display_name
      serializedData = templatefile("${path.module}/hub-governance-workbook.json.tftpl", {
        genai_union_arms = local.genai_union_arms
        bu1_ws           = local.spoke_by_key["bu1"].ws
        bu2_ws           = local.spoke_by_key["bu2"].ws
        bu1_sub          = local.spoke_by_key["bu1"].sub
        bu2_sub          = local.spoke_by_key["bu2"].sub
        hub_sub          = local.hub_sub
        company_options  = local.company_options
      })
      category = "workbook"
      sourceId = var.log_analytics_workspace_resource_id
    }
  }
}
