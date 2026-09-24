variable "name" {
  type        = string
  description = "API Center service name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_id" {
  type        = string
  description = "Resource group resource id (parent for the API Center service)."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}

variable "register_mcp_api" {
  type        = bool
  description = "Register the MCP tool as an API in the catalog's default workspace."
  default     = true
}

variable "mcp_api_name" {
  type        = string
  description = "Catalog API resource name for the MCP tool."
  default     = "mcp-governed-read"
}

variable "mcp_api_title" {
  type        = string
  description = "Display title for the MCP tool in the catalog."
  default     = "MCP governed read"
}

variable "mcp_api_summary" {
  type        = string
  description = "Catalog summary for the MCP tool."
  default     = "Least-privilege MCP tool; classification-checked read, reachable only via the APIM AI Gateway."
}
