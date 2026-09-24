output "initiative_id" {
  description = "Resource id of the policy set definition (initiative)."
  value       = azurerm_policy_set_definition.this.id
}

output "initiative_name" {
  description = "Name of the policy set definition."
  value       = azurerm_policy_set_definition.this.name
}

output "assignment_id" {
  description = "Resource id of the subscription assignment, or null when not assigned."
  value       = try(azurerm_subscription_policy_assignment.this[0].id, null)
}

output "assignment_principal_id" {
  description = "System-assigned identity principal id of the assignment (for remediation role grants), or null."
  value       = try(azurerm_subscription_policy_assignment.this[0].identity[0].principal_id, null)
}
