variable "name" {
  type        = string
  description = "Policy set (initiative) resource name."
  default     = "agent-factory-ai-guardrails"
}

variable "display_name" {
  type        = string
  description = "Initiative display name."
  default     = "agent platform - AI platform guardrails (audit-first)"
}

variable "description" {
  type        = string
  description = "Initiative description."
  default     = "Curated built-in guardrails for the agent platform: seal the model backends, require keyless and private access, govern tags and locations, and keep telemetry flowing. Effects default to Audit so the initiative reports without blocking; raise to Deny / Modify per tenant once findings are clean."
}

variable "management_group_id" {
  type        = string
  description = "Management group resource id to host the initiative + assignment. Null hosts them at the provider subscription scope."
  default     = null
}

variable "audit_effect" {
  type        = string
  description = "Effect for the audit-capable guardrails. Audit reports only; Deny blocks non-compliant creates."
  default     = "Audit"

  validation {
    condition     = contains(["Audit", "Deny", "Disabled"], var.audit_effect)
    error_message = "audit_effect must be Audit, Deny, or Disabled."
  }
}

variable "configure_effect" {
  type        = string
  description = "Effect for the Cognitive Services remediation guardrails (disable public network / local auth). Disabled keeps them inert (audit-first); Modify auto-seals resources."
  default     = "Disabled"

  validation {
    condition     = contains(["Modify", "Disabled"], var.configure_effect)
    error_message = "configure_effect must be Modify or Disabled."
  }
}

variable "diagnostics_effect" {
  type        = string
  description = "Effect for the diagnostics-to-hub guardrail. DeployIfNotExists ships resource diagnostics to the hub workspace; Disabled leaves it inert. Only used when log_analytics_workspace_id is set."
  default     = "Disabled"

  validation {
    condition     = contains(["DeployIfNotExists", "Disabled"], var.diagnostics_effect)
    error_message = "diagnostics_effect must be DeployIfNotExists or Disabled."
  }
}

variable "allowed_locations" {
  type        = list(string)
  description = "Regions resources may deploy to (data-residency guardrail)."
  default     = ["eastus2", "eastus", "westus", "westus3", "swedencentral"]
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Hub Log Analytics workspace resource id. When set, adds a DeployIfNotExists diagnostics guardrail (default effect Disabled) targeting this workspace. Empty omits the guardrail."
  default     = ""
}

variable "enable_approved_models_policy" {
  type        = bool
  description = "Add the Foundry approved-models guardrail. Off by default until you define your approved model list, since an empty allow-list audits every deployment as non-compliant."
  default     = false
}

variable "allowed_model_publishers" {
  type        = list(string)
  description = "Model publishers allowed when enable_approved_models_policy is true."
  default     = ["OpenAI", "Microsoft", "Meta", "Mistral AI"]
}

variable "enable_assignment" {
  type        = bool
  description = "Create the subscription assignment. Off by default: committing the initiative should not deploy an assignment. Azure Policy is per-tenant, so each federated tenant assigns its own copy."
  default     = false
}

variable "assignment_name" {
  type        = string
  description = "Policy assignment name (kept short for scope name limits)."
  default     = "af-ai-guardrails"
}

variable "assignment_subscription_id" {
  type        = string
  description = "Subscription id (GUID) to scope the assignment to. Required when enable_assignment is true."
  default     = ""
}

variable "assignment_location" {
  type        = string
  description = "Region for the assignment's system-assigned identity (required for the remediation-capable members)."
  default     = "eastus2"
}

variable "enforce" {
  type        = bool
  description = "Assignment enforcement. True evaluates and applies effects (Audit still only reports); false is DoNotEnforce (what-if)."
  default     = true
}
