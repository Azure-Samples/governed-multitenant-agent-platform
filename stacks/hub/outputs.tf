output "resource_group_name" {
  description = "Hub resource group."
  value       = module.resource_group.name
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource id (spokes send telemetry here)."
  value       = module.log_analytics.resource_id
}

output "audit_storage_account_id" {
  description = "Immutable (WORM) audit storage account resource id."
  value       = module.audit_storage.resource_id
}

output "workbook_id" {
  description = "Hub telemetry + ROI workbook resource id."
  value       = module.workbook.resource_id
}
