output "resource_group_name" {
  description = "Harness resource group (custom seams: MCP tool, ACR, PDP)."
  value       = module.resource_group.name
}

# R1 gateway values come from stacks/spoke-gateway (the adopted accelerator).
# Null when enable_gateway_integration is false (no large-compute accelerator deployed).
output "gateway_url" {
  description = "APIM gateway base URL (from spoke-gateway; null when the accelerator is not integrated)."
  value       = try(data.terraform_remote_state.gateway[0].outputs.apim_gateway_url, null)
}

output "model_endpoints" {
  description = "AI Foundry model endpoints the gateway fronts (from spoke-gateway; null when the accelerator is not integrated)."
  value       = try(data.terraform_remote_state.gateway[0].outputs.ai_foundry_endpoints, null)
}

output "key_vault_uri" {
  description = "Gateway Key Vault URI (from spoke-gateway; null when the accelerator is not integrated)."
  value       = try(data.terraform_remote_state.gateway[0].outputs.key_vault_uri, null)
}

output "event_bus_namespace" {
  description = "Event Hub namespace (X-3 event bus) provided by the accelerator (from spoke-gateway; null when the accelerator is not integrated)."
  value       = try(data.terraform_remote_state.gateway[0].outputs.eventhub_namespace, null)
}

output "mcp_tool_url" {
  description = "MCP tool container app URL."
  value       = module.mcp_tool.fqdn_url
}

output "acr_login_server" {
  description = "Login server of the immutable artifact registry for the MCP tool image."
  value       = module.acr.login_server
}

output "pdp_url" {
  description = "OPA policy decision point base URL (A-1.3)."
  value       = module.policy_engine.pdp_url
}

output "log_analytics_workspace_id" {
  description = "Harness Log Analytics workspace id (telemetry sink for the MCP tool + PDP). Point the hub workbook here over Lighthouse to see spoke signals. A full spoke also has the gateway's own workspace."
  value       = module.log_analytics.resource_id
}

output "lighthouse_registration_id" {
  description = "Lighthouse registration definition id (null when delegation is disabled)."
  value       = try(module.lighthouse[0].registration_definition_id, null)
}

output "foundry_endpoint" {
  description = "Azure AI Foundry account endpoint (null unless enable_foundry)."
  value       = try(module.foundry[0].endpoint, null)
}

output "foundry_name" {
  description = "Azure AI Foundry account name."
  value       = try(module.foundry[0].name, null)
}

output "foundry_resource_id" {
  description = "Azure AI Foundry account resource id."
  value       = try(module.foundry[0].resource_id, null)
}

output "content_safety_endpoint" {
  description = "Content Safety account endpoint (null unless enable_foundry)."
  value       = try(module.content_safety[0].endpoint, null)
}
