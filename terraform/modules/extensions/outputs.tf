###############################################################################
# Module: extensions — outputs.tf
###############################################################################

output "custom_script_extension_id" {
  description = "Resource ID of the Custom Script Extension if enabled."
  value       = var.enable_custom_script ? azurerm_virtual_machine_extension.custom_script[0].id : null
}

output "domain_join_extension_id" {
  description = "Resource ID of the Domain Join Extension if enabled."
  value       = var.enable_domain_join && var.os_type == "Windows" ? azurerm_virtual_machine_extension.domain_join[0].id : null
}

output "azure_monitor_agent_id" {
  description = "Resource ID of the Azure Monitor Agent extension if enabled."
  value       = var.enable_monitoring ? azurerm_virtual_machine_extension.azure_monitor_agent[0].id : null
}

output "dependency_agent_id" {
  description = "Resource ID of the Dependency Agent extension if enabled."
  value       = var.enable_monitoring ? azurerm_virtual_machine_extension.dependency_agent[0].id : null
}
