output "fqdn_url" {
  description = "Public URL of the MCP tool container app."
  value       = module.containerapp.fqdn_url
}

output "resource_id" {
  description = "Container App resource id."
  value       = module.containerapp.resource_id
}

output "identity_principal_id" {
  description = "System-assigned managed identity principal id of the MCP tool (for AcrPull)."
  value       = try(module.containerapp.identity[0].principal_id, null)
}
