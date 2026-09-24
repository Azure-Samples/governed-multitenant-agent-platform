variable "name" {
  type        = string
  description = "APIM instance name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to deploy into."
}

variable "publisher_email" {
  type        = string
  description = "APIM publisher email."
}

variable "publisher_name" {
  type        = string
  description = "APIM publisher / organization name."
}

variable "sku_name" {
  type        = string
  description = "APIM SKU. Developer_1 for the POC."
  default     = "Developer_1"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}

variable "gateway_policy_xml" {
  type        = string
  description = "Optional override for the service-level AI Gateway policy XML. Defaults to the module's built-in policy (correlation-id + TODO switches)."
  default     = null
}

variable "log_analytics_workspace_resource_id" {
  type        = string
  description = "Optional Log Analytics workspace resource id for gateway diagnostics (R4). When null, no diagnostic setting is created."
  default     = null
}

variable "model_backend_url" {
  type        = string
  description = "Optional model endpoint to register as a governed backend in the gateway."
  default     = null
}

variable "model_backend_resource_id" {
  type        = string
  description = "ARM resource id of the model account, for managed-identity backend auth."
  default     = null
}

variable "pdp_url" {
  type        = string
  description = "Optional base URL of the external Policy Decision Point (OPA PDP, A-1.3). When set, the gateway PEP (B-2.3) calls it for an allow/deny decision on every request, fail-closed."
  default     = null
}
