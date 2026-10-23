###############################################################################
# Module: extensions
# Purpose: Deploys VM extensions in order:
#   1. Custom Script Extension  — bootstraps the OS
#   2. Domain Join Extension    — joins the VM to an AD / Entra ID domain
#   3. Azure Monitor Agent      — modern replacement for MMA/OMS
#   4. Dependency Agent         — enables Service Map & VM Insights
#
# Design note:  Extensions must run sequentially on Windows because the Guest
# Agent serialises them, but we still express Terraform depends_on to make
# the ordering crystal-clear and prevent resource graph races.
###############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.85.0"
    }
  }
}

locals {
  # Determine the publisher/type for the domain-join extension based on OS.
  dj_publisher = var.os_type == "Windows" ? "Microsoft.Compute" : "Microsoft.Azure.Extensions"
  dj_type      = var.os_type == "Windows" ? "JsonADDomainExtension" : "CustomScript"
  dj_type_ver  = var.os_type == "Windows" ? "1.3" : "2.1"

  # AMA differs between Windows and Linux
  ama_publisher = var.os_type == "Windows" ? "Microsoft.Azure.Monitor" : "Microsoft.Azure.Monitor"
  ama_type      = var.os_type == "Windows" ? "AzureMonitorWindowsAgent" : "AzureMonitorLinuxAgent"
  ama_type_ver  = var.os_type == "Windows" ? "1.0" : "1.0"
}

# ---------------------------------------------------------------------------
# 1. Custom Script Extension — software bootstrap
#    Runs first because domain join may depend on software (e.g. RSAT tools).
# ---------------------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "custom_script" {
  count = var.enable_custom_script ? 1 : 0

  name                       = "CustomScriptExtension"
  virtual_machine_id         = var.vm_id
  publisher                  = var.os_type == "Windows" ? "Microsoft.Compute" : "Microsoft.Azure.Extensions"
  type                       = var.os_type == "Windows" ? "CustomScriptExtension" : "CustomScript"
  type_handler_version       = var.os_type == "Windows" ? "1.10" : "2.1"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  # The settings block is not sensitive — it just points at the script.
  settings = jsonencode({
    fileUris = var.script_file_uris
  })

  # The protected_settings block IS sensitive — it contains the SAS token
  # that grants read access to the blob container holding the script.
  protected_settings = jsonencode({
    commandToExecute   = var.script_command
    storageAccountName = var.script_storage_account_name
    storageAccountKey  = var.script_storage_account_key
  })

  # Lifecycle hook — if the script URI changes we want a fresh run, not
  # an in-place update that might be silently skipped by the guest agent.
  lifecycle {
    replace_triggered_by = [azurerm_virtual_machine_extension.custom_script]
  }
}

# ---------------------------------------------------------------------------
# 2. Domain Join Extension (Windows only)
#    Needs to run AFTER custom_script so required tools are present.
# ---------------------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "domain_join" {
  count = var.enable_domain_join && var.os_type == "Windows" ? 1 : 0

  name                       = "DomainJoin"
  virtual_machine_id         = var.vm_id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  settings = jsonencode({
    Name    = var.domain_name
    OUPath  = var.domain_ou_path
    User    = var.domain_join_user
    Restart = "true"
    Options = "3" # 3 = NetSetupJoinDomain | NetSetupAcctCreate
  })

  protected_settings = jsonencode({
    Password = var.domain_join_password
  })

  depends_on = [azurerm_virtual_machine_extension.custom_script]
}

# ---------------------------------------------------------------------------
# 3. Azure Monitor Agent (AMA)
#    Replaces the legacy Log Analytics agent (MMA/OMS).
#    Requires a Data Collection Rule association — see the monitoring module.
# ---------------------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "azure_monitor_agent" {
  count = var.enable_monitoring ? 1 : 0

  name                       = "AzureMonitorAgent"
  virtual_machine_id         = var.vm_id
  publisher                  = local.ama_publisher
  type                       = local.ama_type
  type_handler_version       = local.ama_type_ver
  auto_upgrade_minor_version = true
  tags                       = var.tags

  settings = jsonencode({
    authentication = {
      managedIdentity = {
        identifier-name  = "mi_res_id"
        identifier-value = var.vm_principal_id
      }
    }
  })

  depends_on = [azurerm_virtual_machine_extension.domain_join]
}

# ---------------------------------------------------------------------------
# 4. Dependency Agent  (VM Insights / Service Map)
# ---------------------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "dependency_agent" {
  count = var.enable_monitoring ? 1 : 0

  name                       = "DependencyAgent"
  virtual_machine_id         = var.vm_id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = var.os_type == "Windows" ? "DependencyAgentWindows" : "DependencyAgentLinux"
  type_handler_version       = "9.10"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  settings = jsonencode({
    enableAMA = "true"
  })

  depends_on = [azurerm_virtual_machine_extension.azure_monitor_agent]
}
