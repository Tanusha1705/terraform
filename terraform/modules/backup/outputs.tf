###############################################################################
# Module: backup — outputs.tf
###############################################################################

output "vault_id" {
  description = "Resource ID of the Recovery Services Vault (created or existing)."
  value       = var.create_vault ? azurerm_recovery_services_vault.this[0].id : var.existing_vault_id
}

output "policy_id" {
  description = "Resource ID of the backup policy."
  value       = local.policy_id
}

output "protected_vm_id" {
  description = "Resource ID of the backup-protected VM resource."
  value       = azurerm_backup_protected_vm.this.id
}
