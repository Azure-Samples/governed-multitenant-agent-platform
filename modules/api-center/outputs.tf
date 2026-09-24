output "resource_id" {
  description = "API Center service resource id."
  value       = azapi_resource.service.id
}

output "name" {
  description = "API Center service name."
  value       = azapi_resource.service.name
}

output "identity_principal_id" {
  description = "System-assigned identity principal id of the API Center service."
  value       = try(azapi_resource.service.identity[0].principal_id, null)
}
