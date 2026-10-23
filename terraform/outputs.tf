###############################################################################
# Root module — outputs.tf
###############################################################################

output "vm_id" {
  description = "Resource ID of the provisioned VM."
  value       = module.vm.vm_id
}

output "vm_name" {
  description = "Name of the provisioned VM."
  value       = module.vm.vm_name
}

output "private_ip_address" {
  description = "Private IP assigned to the VM's NIC."
  value       = module.vm.private_ip_address
}

output "public_ip_address" {
  description = "Public IP address, empty string when none was created."
  value       = module.vm.public_ip_address
}

output "principal_id" {
  description = "Managed identity principal ID — use this for RBAC assignments."
  value       = module.vm.principal_id
}

output "backup_vault_id" {
  description = "Resource ID of the Recovery Services Vault."
  value       = var.enable_backup ? module.backup[0].vault_id : null
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace."
  value       = var.enable_monitoring ? module.monitoring[0].workspace_id : null
}
