output "action_group_id" {
  value       = azurerm_monitor_action_group.hub.id
  description = "Resource id of the hub action group."
}

output "alert_rule_ids" {
  value = {
    token_spend     = azurerm_monitor_scheduled_query_rules_alert_v2.token_spend.id
    exception_spike = azurerm_monitor_scheduled_query_rules_alert_v2.exception_spike.id
  }
  description = "Resource ids of the scheduled-query alert rules."
}

output "budget_id" {
  value       = azurerm_consumption_budget_subscription.hub.id
  description = "Resource id of the hub subscription budget."
}
