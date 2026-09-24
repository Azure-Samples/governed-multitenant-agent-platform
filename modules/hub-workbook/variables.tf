variable "workbook_id" {
  type        = string
  description = "Workbook resource name (must be a GUID). Defaults to the live demo workbook."
  default     = "9a9a5b01-022a-4d13-94db-7074f5902da5"
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_id" {
  type        = string
  description = "Resource group resource id (parent for the workbook)."
}

variable "log_analytics_workspace_resource_id" {
  type        = string
  description = "Log Analytics workspace the workbook queries against."
}

variable "display_name" {
  type        = string
  description = "Workbook display name."
  default     = "governed agent platform dashboard"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}

