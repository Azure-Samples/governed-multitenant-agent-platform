variable "name" {
  type        = string
  description = "Container App name for the MCP tool."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group to deploy into."
}

variable "container_app_environment_resource_id" {
  type        = string
  description = "Resource id of the Container App Environment to host the MCP tool."
}

variable "location" {
  type        = string
  description = "Azure region. Defaults to the resource group location when null."
  default     = null
}

variable "image" {
  type        = string
  description = "Container image. Placeholder sample until the real MCP server image is built."
  default     = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

variable "target_port" {
  type        = number
  description = "Container port the ingress routes to."
  default     = 80
}

variable "registry_server" {
  type        = string
  description = "Login server of the private registry holding the MCP image (e.g. acrgovagent<env>.azurecr.io). When set, the app authenticates to it with its system-assigned identity, which must hold AcrPull. Leave null for the public placeholder image."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}

variable "env_vars" {
  type        = map(string)
  description = "Non-secret environment variables for the tool container (name => value)."
  default     = {}
}

variable "secret_env_vars" {
  type        = map(string)
  description = "Secret environment variables (name => value). Each becomes a Container Apps secret plus an env var sourced from it."
  default     = {}
  sensitive   = true
}

variable "min_replicas" {
  type        = number
  description = "Minimum replica count. 0 = scale to zero (cheapest); 1 = always warm (no cold-start)."
  default     = 0
}
