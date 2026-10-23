###############################################################################
# Module: vm — outputs.tf
#
# These outputs are intentionally named to be composable — callers can pass
# them straight into the extension, backup, and monitoring modules without
# any transformation.
###############################################################################

output "vm_id" {
  description = "The resource ID of the virtual machine."
  value       = var.os_type == "Windows" ? azurerm_windows_virtual_machine.this[0].id : azurerm_linux_virtual_machine.this[0].id
}

output "vm_name" {
  description = "The name of the virtual machine (useful for constructing extension names)."
  value       = var.os_type == "Windows" ? azurerm_windows_virtual_machine.this[0].name : azurerm_linux_virtual_machine.this[0].name
}

output "private_ip_address" {
  description = "The private IP that Azure assigned to the NIC."
  value       = azurerm_network_interface.this.private_ip_address
}

output "public_ip_address" {
  description = "The public IP address, or an empty string when no PIP was created."
  value       = var.create_public_ip ? azurerm_public_ip.this[0].ip_address : ""
}

output "nic_id" {
  description = "Resource ID of the network interface card."
  value       = azurerm_network_interface.this.id
}

output "principal_id" {
  description = "The system-assigned managed identity principal ID — use this for RBAC assignments."
  value       = var.os_type == "Windows" ? azurerm_windows_virtual_machine.this[0].identity[0].principal_id : azurerm_linux_virtual_machine.this[0].identity[0].principal_id
}

output "os_type" {
  description = "Echoes back the os_type so downstream modules don't need to carry the variable themselves."
  value       = var.os_type
}
