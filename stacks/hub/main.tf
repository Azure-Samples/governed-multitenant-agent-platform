locals {
  tags = merge({
    workload    = "agent-factory"
    plane       = "hub"
    project     = "governed-multitenant-agent-platform"
    environment = "demo"
    owner       = "demo"
    managed_by  = "terraform"
  }, var.tags)
}

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name             = "rg-agentfactory-hub"
  location         = var.location
  tags             = local.tags
  enable_telemetry = false
}

# telemetry sink: gateway + agent telemetry lands here (spokes send via diagnostics + Lighthouse)
module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                                      = "law-agentfactory-hub"
  location                                  = var.location
  resource_group_name                       = module.resource_group.name
  log_analytics_workspace_retention_in_days = 30
  # Demo hub is query-only ("view, don't store"): allow public query so the cross-workspace
  # board and the hub-anchored cap-14a CLI resolve; ingestion stays private (nothing ingests here).
  log_analytics_workspace_internet_query_enabled = "true"
  enable_telemetry                               = false
  tags                                           = local.tags
}

# Random suffix keeps the globally-unique storage account name from colliding.
resource "random_string" "audit_suffix" {
  length  = 5
  lower   = true
  numeric = true
  upper   = false
  special = false
}

# immutable (WORM) audit sink
# Storage account names are global and <= 24 lowercase alphanumerics; base (19) + suffix (5)
# stays within the limit and stays stable once written to state.
module "audit_storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.9.0"

  name             = "stagentfactoryaudit${random_string.audit_suffix.result}"
  location         = var.location
  parent_id        = module.resource_group.resource_id
  account_kind     = "StorageV2"
  account_sku_name = "Standard_ZRS"
  tags             = local.tags
  enable_telemetry = false

  # WORM: account-level immutability. Unlocked lets the retention period change during the
  # POC; move to Locked (irreversible) for production.
  immutability_policy = {
    allow_protected_append_writes = true
    period_since_creation_in_days = var.audit_retention_days
    state                         = "Unlocked"
  }

  blob_properties = {
    versioning_enabled = true
  }

  containers = {
    audit = { name = "audit" }
  }
}

# hub dashboard: telemetry + illustrative ROI workbook over the Log Analytics workspace
module "workbook" {
  source = "../../modules/hub-workbook"

  location                            = var.location
  resource_group_id                   = module.resource_group.resource_id
  log_analytics_workspace_resource_id = module.log_analytics.resource_id
  tags                                = local.tags
}

# hub-side fleet alerting + FinOps budget: an action group, two cross-workspace
# scheduled-query alerts (fleet token spend, fleet exception spike), and a subscription budget.
# Cross-tenant alert firing over Lighthouse is validated after the first clean 200; the budget is
# hub-local and always works. Spoke workspace ids, email, and thresholds use the module defaults.
module "alerts" {
  source = "../../modules/hub-alerts"

  resource_group_name                 = module.resource_group.name
  location                            = var.location
  subscription_id                     = var.subscription_id
  log_analytics_workspace_resource_id = module.log_analytics.resource_id
  # TEMP demo pre-arm (2026-08-28): lowered so the fleet exception-spike alert trips on ambient
  # spoke exceptions and produces a real fired alert; revert to the module default (5000) after.
  exception_hourly_threshold = 5
  tags                       = local.tags
}

# TODO: Azure Lighthouse delegation (no AVM module yet -> thin azapi/azurerm wrapper) so
#      spoke telemetry rolls up to this hub. Needs the managing tenant + principal object ids.
