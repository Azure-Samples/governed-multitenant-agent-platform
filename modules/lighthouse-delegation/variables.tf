variable "subscription_scope" {
  type        = string
  description = "The subscription being delegated, as a scope id: /subscriptions/<id>."
}

variable "managing_tenant_id" {
  type        = string
  description = "Managing (hub) tenant id that receives delegated access."
}

variable "definition_name" {
  type        = string
  description = "Human-readable name for the Lighthouse registration definition."
  default     = "Agent Factory hub telemetry rollup"
}

variable "authorizations" {
  type = list(object({
    principal_id           = string
    role_definition_id     = string
    principal_display_name = string
  }))
  description = "Hub principals and the built-in role definition GUIDs they receive on this subscription."
}

variable "registration_definition_id" {
  type        = string
  description = "Registration definition resource name (GUID)."
  default     = "b7f1c2d3-e4a5-4b60-9c71-2d3e4f5a6b70"
}

variable "registration_assignment_id" {
  type        = string
  description = "Registration assignment resource name (GUID)."
  default     = "c8a2d3e4-f5b6-4c71-8d92-3e4f5a6b7c81"
}
