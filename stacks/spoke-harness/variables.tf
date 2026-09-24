variable "subscription_id" {
  type        = string
  description = "Target subscription for the harness (spoke-app Application)."
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

variable "environment" {
  type        = string
  description = "Environment name. Env isolation is resource-group level for the POC; also the per-spoke discriminator baked into globally-unique names (ACR)."

  validation {
    condition     = contains(["dev", "prod", "rmk2"], var.environment)
    error_message = "environment must be dev, prod, or rmk2."
  }
}

variable "enable_gateway_integration" {
  type        = bool
  description = "Read the adopted accelerator (spoke-gateway) remote state and surface its gateway/model/Key Vault/event-bus outputs. Off by default so a standard harness deploy needs no large-compute accelerator (App Service / APIM / Cosmos / Event Hub / private endpoints). Set true only where the accelerator is already deployed."
  default     = false
}

variable "acr_sku" {
  type        = string
  description = "SKU for the MCP tool image registry. Premium is the default (private endpoints, retention). Use Basic or Standard to dodge Premium capacity/cost limits in a constrained spoke."
  default     = "Premium"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "acr_sku must be Basic, Standard, or Premium."
  }
}

variable "mcp_tool_image" {
  type        = string
  description = "Container image for the MCP tool (ca-mcp-<env>). Defaults to the hello-world placeholder; set to the governed-read image in the spoke ACR (e.g. acragentfac<env>.azurecr.io/governed-sop-read:v1) once it is built and pushed, then apply to flip ca-mcp off the placeholder."
  default     = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

variable "mcp_tool_target_port" {
  type        = number
  description = "Ingress target port for the MCP tool. 80 for the hello-world placeholder; set to 8080 (the governed-read Dockerfile's EXPOSE) when mcp_tool_image points at the real image."
  default     = 80
}

variable "mcp_tool_registry_server" {
  type        = string
  description = "Login server of the spoke ACR (acragentfac<env>.azurecr.io) so the MCP tool pulls its private image via its managed identity (AcrPull is granted in main.tf). Set together with mcp_tool_image in phase 2, after az acr build. Null for the public placeholder."
  default     = null
}

variable "mcp_tool_env_vars" {
  type        = map(string)
  description = "Non-secret env vars for the MCP tool container (e.g. PDP_URL for the OPA pre-check)."
  default     = {}
}

variable "mcp_tool_secret_env_vars" {
  type        = map(string)
  description = "Secret env vars for the MCP tool (e.g. API_KEY_* that bind clearance to a credential). Become Container Apps secrets."
  default     = {}
  sensitive   = true
}

variable "keep_warm" {
  type        = bool
  description = "Pin the MCP tool and PDP to one always-on replica (no cold-start false-denies). Costs a little more; use for demos."
  default     = false
}

variable "gateway_state_resource_group_name" {
  type        = string
  description = "Resource group of the spoke-gateway remote state storage account. Required when enable_gateway_integration is true."
  default     = null
}

variable "gateway_state_storage_account_name" {
  type        = string
  description = "Storage account holding the spoke-gateway remote state. Required when enable_gateway_integration is true."
  default     = null
}

variable "gateway_state_container_name" {
  type        = string
  description = "Blob container holding the spoke-gateway remote state."
  default     = "tfstate"
}

variable "gateway_state_key" {
  type        = string
  description = "State key of the spoke-gateway stack for this spoke (e.g. spoke-gateway-<name>.tfstate). Required when enable_gateway_integration is true."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Extra tags merged onto every resource."
  default     = {}
}

variable "enable_lighthouse" {
  type        = bool
  description = "Delegate this subscription to the hub tenant via Azure Lighthouse for telemetry/cost rollup."
  default     = false
}

variable "hub_tenant_id" {
  type        = string
  description = "Managing (hub) tenant id for Lighthouse delegation. Required when enable_lighthouse is true."
  default     = null
}

variable "lighthouse_principal_id" {
  type        = string
  description = "Object id of the hub principal (an Entra group is recommended) granted read access via Lighthouse."
  default     = null
}

variable "lighthouse_principal_display_name" {
  type        = string
  description = "Display name for the Lighthouse authorization."
  default     = "Agent Factory Hub"
}

variable "enable_foundry" {
  type        = bool
  description = "Deploy an Azure AI Foundry (AIServices) account + a model deployment + a Content Safety account so this spoke can host an agent that reaches data only through the governed MCP tool. Off by default (lite spokes are tool-only)."
  default     = false
}

variable "foundry_location" {
  type        = string
  description = "Region for the Foundry + Content Safety accounts and the model deployment. Defaults to the spoke location; override where the spoke region lacks model quota (e.g. swedencentral)."
  default     = null
}

variable "foundry_model" {
  type        = string
  description = "OpenAI model to deploy in the Foundry account."
  default     = "gpt-4o"
}

variable "foundry_model_version" {
  type        = string
  description = "Model version for foundry_model."
  default     = "2024-11-20"
}

variable "foundry_model_capacity" {
  type        = number
  description = "Deployment capacity in thousands of TPM. Keep under the region quota."
  default     = 20
}
