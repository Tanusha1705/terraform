###############################################################################
# Module: backup
# Purpose: Associates a VM with an Azure Recovery Services Vault and assigns
#          a backup policy.  Optionally creates the vault and policy when no
#          existing ones are provided.
###############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.85.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Optionally create the Recovery Services Vault
# ---------------------------------------------------------------------------
resource "azurerm_recovery_services_vault" "this" {
  count = var.create_vault ? 1 : 0

  name                = var.vault_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"

  # Soft-delete keeps deleted backup data for 14 additional days — leave
  # enabled in prod; you can override in dev environments to speed up teardown.
  soft_delete_enabled = var.soft_delete_enabled

  # Immutability helps satisfy compliance requirements like SOC 2 and ISO 27001.
  immutability = var.vault_immutability # "Locked", "Unlocked", or "Disabled"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

locals {
  vault_id = var.create_vault ? azurerm_recovery_services_vault.this[0].id : var.existing_vault_id
}

# ---------------------------------------------------------------------------
# Backup policy for Azure VMs
# ---------------------------------------------------------------------------
resource "azurerm_backup_policy_vm" "this" {
  count = var.create_policy ? 1 : 0

  name                = var.policy_name
  resource_group_name = var.resource_group_name
  recovery_vault_name = var.create_vault ? azurerm_recovery_services_vault.this[0].name : var.existing_vault_name

  # The timezone must match what the platform ops team agreed on — defaulting
  # to UTC avoids surprises across multi-region deployments.
  timezone = var.backup_timezone

  backup {
    frequency = var.backup_frequency # Daily or Weekly
    time      = var.backup_time      # 24-hour format "23:00"
  }

  retention_daily {
    count = var.retention_daily_count
  }

  dynamic "retention_weekly" {
    for_each = var.retention_weekly_count > 0 ? { "weekly" = true } : {}
    content {
      count    = var.retention_weekly_count
      weekdays = var.retention_weekly_weekdays
    }
  }

  dynamic "retention_monthly" {
    for_each = var.retention_monthly_count > 0 ? { "monthly" = true } : {}
    content {
      count    = var.retention_monthly_count
      weekdays = var.retention_monthly_weekdays
      weeks    = var.retention_monthly_weeks
    }
  }
}

locals {
  policy_id = var.create_policy ? azurerm_backup_policy_vm.this[0].id : var.existing_policy_id
}

# ---------------------------------------------------------------------------
# Protect the VM with the policy
# ---------------------------------------------------------------------------
resource "azurerm_backup_protected_vm" "this" {
  resource_group_name = var.resource_group_name
  recovery_vault_name = var.create_vault ? azurerm_recovery_services_vault.this[0].name : var.existing_vault_name
  source_vm_id        = var.vm_id
  backup_policy_id    = local.policy_id

  # Azure takes a few seconds to register the VM after it's created, so
  # tolerate transient 409 conflicts by letting Terraform retry.
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}
