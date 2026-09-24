variable "subscription_id" {
  type        = string
  description = "Management subscription for the observability hub (hub)."
}

variable "tenant_id" {
  type        = string
  description = "Entra tenant id for the deployment identity."
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "eastus2"
}

variable "audit_retention_days" {
  type        = number
  description = "WORM immutability period (days) for the audit sink."
  default     = 365
}

variable "tags" {
  type        = map(string)
  description = "Extra tags merged onto every resource."
  default     = {}
}
