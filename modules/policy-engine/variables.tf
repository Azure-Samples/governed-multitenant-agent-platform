variable "name" {
  type        = string
  description = "Container App name for the OPA policy engine (PDP)."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to deploy into."
}

variable "container_app_environment_resource_id" {
  type        = string
  description = "Resource id of the Container App Environment to host the PDP."
}

variable "location" {
  type        = string
  description = "Azure region. Defaults to the resource group location when null."
  default     = null
}

variable "image" {
  type        = string
  description = "OPA container image."
  default     = "openpolicyagent/opa:latest"
}

variable "authz_rego" {
  type        = string
  description = "Rego policy bundle content loaded into OPA (the PDP decision policy)."
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}

variable "min_replicas" {
  type        = number
  description = "Minimum replica count. 0 = scale to zero (cheapest); 1 = always warm (no cold-start false-denies)."
  default     = 0
}
