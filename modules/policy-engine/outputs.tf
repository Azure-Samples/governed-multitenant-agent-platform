output "pdp_url" {
  description = "Base URL of the OPA policy decision point (the gateway PEP calls this)."
  value       = module.containerapp.fqdn_url
}

output "resource_id" {
  description = "PDP Container App resource id."
  value       = module.containerapp.resource_id
}

output "identity_principal_id" {
  description = "System-assigned managed identity principal id of the PDP."
  value       = try(module.containerapp.identity[0].principal_id, null)
}
