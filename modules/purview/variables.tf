variable "name" {
  type        = string
  description = "Name of the Microsoft Purview account (3 to 63 chars, globally unique, letters/numbers/hyphens)."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to deploy the Purview account into."
}

variable "location" {
  type        = string
  description = "Azure region for the Purview account."
}

variable "public_network_enabled" {
  type        = bool
  description = "Whether the account is reachable over the public network. Set false and add private endpoints for a sealed production posture."
  default     = true
}

variable "managed_resource_group_name" {
  type        = string
  description = "Optional name for the Purview-managed resource group (ingestion storage and event hub). Null lets Azure generate one."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the account. Include project=governed-multitenant-agent-platform per the harness convention."
  default     = {}
}
