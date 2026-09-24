variable "resource_group_name" {
  type        = string
  description = "Hub resource group name (holds the action group and alert rules)."
}

variable "location" {
  type        = string
  description = "Azure region for the scheduled-query alert rules."
}

variable "subscription_id" {
  type        = string
  description = "Hub subscription GUID (budget scope)."
}

variable "log_analytics_workspace_resource_id" {
  type        = string
  description = "Hub Log Analytics workspace resource id (alert-rule evaluation scope)."
}

variable "spoke_workspace_ids" {
  type        = list(string)
  description = "Full resource ids of the governed spoke Log Analytics workspaces the alerts read cross-workspace over Lighthouse. Add one entry per enrolled company."
  default = [
    "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-prod/providers/microsoft.operationalinsights/workspaces/law-bu1",
    "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-dev/providers/microsoft.operationalinsights/workspaces/law-bu2"
  ]
}

variable "alert_email" {
  type        = string
  description = "Email address that receives alert and budget notifications."
  default     = "admin@MngEnv421485.onmicrosoft.com"
}

variable "monthly_budget_usd" {
  type        = number
  description = "Monthly Azure spend budget (USD) for the hub subscription."
  default     = 200
}

variable "budget_start_date" {
  type        = string
  description = "Budget start date (must be the first day of a month, RFC3339)."
  default     = "2026-08-01T00:00:00Z"
}

variable "token_daily_threshold" {
  type        = number
  description = "Fire the token-spend alert when a day's total agent tokens across the fleet exceed this."
  default     = 500000
}

variable "spoke_token_daily_threshold" {
  type        = number
  description = "Fire the per-spoke token-spend alert when any single spoke tenant's daily agent tokens exceed this. Set below token_daily_threshold so one runaway tenant trips before the fleet cap."
  default     = 250000
}

variable "spoke_bu_labels" {
  type        = map(string)
  description = "Optional friendly business-unit name per spoke workspace resource id, used to name the per-tenant alert. Falls back to the workspace name if a workspace is not listed."
  default = {
    "/subscriptions/22222222-2222-2222-2222-222222222222/resourceGroups/rg-prod/providers/microsoft.operationalinsights/workspaces/law-bu1" = "Business unit 1"
    "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-dev/providers/microsoft.operationalinsights/workspaces/law-bu2"  = "Business unit 2"
  }
}

variable "exception_hourly_threshold" {
  type        = number
  description = "Fire the reliability alert when any single spoke's agent exceptions in the last hour exceed this floor (per-spoke, not fleet total). The alert also reports each spoke's dominant problem and its count versus its own 24-hour baseline."
  default     = 5000
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
