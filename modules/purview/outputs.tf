output "resource_id" {
  description = "The Purview account resource ID."
  value       = azurerm_purview_account.this.id
}

output "name" {
  description = "The Purview account name."
  value       = azurerm_purview_account.this.name
}

output "identity_principal_id" {
  description = "System-assigned managed identity principal ID. Grant it Reader plus data-source roles so it can scan sources."
  value       = azurerm_purview_account.this.identity[0].principal_id
}

output "catalog_endpoint" {
  description = "Purview Data Map / catalog endpoint."
  value       = azurerm_purview_account.this.catalog_endpoint
}

output "scan_endpoint" {
  description = "Purview scan endpoint."
  value       = azurerm_purview_account.this.scan_endpoint
}

output "guardian_endpoint" {
  description = "Purview guardian endpoint."
  value       = azurerm_purview_account.this.guardian_endpoint
}
