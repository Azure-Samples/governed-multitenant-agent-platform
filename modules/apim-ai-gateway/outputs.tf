output "gateway_url" {
  description = "APIM gateway base URL."
  value       = module.apim.apim_gateway_url
}

output "resource_id" {
  description = "APIM resource id."
  value       = module.apim.resource_id
}

output "identity_principal_id" {
  description = "System-assigned managed identity principal id of the gateway (for RBAC to the model and Key Vault)."
  value       = try(module.apim.resource.identity[0].principal_id, null)
}
