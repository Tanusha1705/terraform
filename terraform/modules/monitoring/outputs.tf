###############################################################################
# Module: monitoring — outputs.tf
###############################################################################

output "workspace_id" {
  description = "Resource ID of the Log Analytics Workspace."
  value       = local.workspace_id
}

output "workspace_name" {
  description = "Name of the Log Analytics Workspace — useful in KQL alert queries."
  value       = var.create_workspace ? azurerm_log_analytics_workspace.this[0].name : null
}

output "dcr_id" {
  description = "Resource ID of the Data Collection Rule."
  value       = azurerm_monitor_data_collection_rule.this.id
}

output "action_group_id" {
  description = "Resource ID of the action group — pass into other alert rules."
  value       = var.create_action_group ? azurerm_monitor_action_group.this[0].id : var.existing_action_group_id
}
