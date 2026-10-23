###############################################################################
# Root module — main.tf
#
# This is the composition layer.  It wires together the four child modules
# (vm, extensions, backup, monitoring) and outputs everything a caller needs.
#
# Intended to be called from the environments/prod or environments/dev folders
# by passing a tfvars file — never directly from this directory.
###############################################################################

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.85.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
  }

  # Remote state — update the values to match your storage account.
  # The key is intentionally dynamic so each environment gets its own state file
  # without duplicating this backend block.
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate01" # must be globally unique
    container_name       = "tfstate"
    key                  = "vm-provisioning.tfstate"
    use_oidc             = true # Workload Identity Federation — no stored keys
  }
}

provider "azurerm" {
  features {
    virtual_machine {
      # Don't delete the OS disk when Terraform destroys a VM that was already
      # manually removed from Azure — avoids a hard error mid-pipeline.
      delete_os_disk_on_deletion = true
    }
    recovery_services_vaults {
      recover_soft_deleted_backup_protected_vm = true
    }
  }

  # These are sourced from environment variables set by the pipeline:
  #   ARM_SUBSCRIPTION_ID, ARM_TENANT_ID, ARM_CLIENT_ID
  # When using OIDC (Workload Identity), ARM_USE_OIDC=true is also needed.
  subscription_id = var.subscription_id
}

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

locals {
  common_tags = merge(
    {
      ManagedBy   = "Terraform"
      Environment = var.environment
      Project     = var.project_name
      CostCenter  = var.cost_center
      CreatedDate = formatdate("YYYY-MM-DD", timestamp())
    },
    var.extra_tags
  )
}

# ---------------------------------------------------------------------------
# Module: VM
# ---------------------------------------------------------------------------
module "vm" {
  source = "./modules/vm"

  vm_name             = var.vm_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  environment         = var.environment
  cost_center         = var.cost_center
  extra_tags          = var.extra_tags

  # Network
  subnet_id                     = var.subnet_id
  private_ip_address            = var.private_ip_address
  nsg_id                        = var.nsg_id
  create_public_ip              = var.create_public_ip
  enable_accelerated_networking = var.enable_accelerated_networking

  # Compute
  os_type = var.os_type
  vm_size = var.vm_size

  # Image
  image_publisher = var.image_publisher
  image_offer     = var.image_offer
  image_sku       = var.image_sku
  image_version   = var.image_version

  # Disks
  os_disk_type    = var.os_disk_type
  os_disk_size_gb = var.os_disk_size_gb
  data_disks      = var.data_disks

  # Auth
  admin_username = var.admin_username
  admin_password = var.admin_password
  ssh_public_key = var.ssh_public_key

  # Security
  enable_encryption_at_host = var.enable_encryption_at_host
  availability_zones        = var.availability_zones
  license_type              = var.license_type
}

# ---------------------------------------------------------------------------
# Module: Extensions
# Runs after the VM is created; includes CSE, domain join, AMA, DependencyAgent
# ---------------------------------------------------------------------------
module "extensions" {
  source = "./modules/extensions"

  vm_id           = module.vm.vm_id
  vm_principal_id = module.vm.principal_id
  os_type         = module.vm.os_type
  tags            = local.common_tags

  # Custom Script
  enable_custom_script        = var.enable_custom_script
  script_file_uris            = var.script_file_uris
  script_command              = var.script_command
  script_storage_account_name = var.script_storage_account_name
  script_storage_account_key  = var.script_storage_account_key

  # Domain Join
  enable_domain_join   = var.enable_domain_join
  domain_name          = var.domain_name
  domain_ou_path       = var.domain_ou_path
  domain_join_user     = var.domain_join_user
  domain_join_password = var.domain_join_password

  # Monitoring agents
  enable_monitoring = var.enable_monitoring

  depends_on = [module.vm]
}

# ---------------------------------------------------------------------------
# Module: Backup
# ---------------------------------------------------------------------------
module "backup" {
  count  = var.enable_backup ? 1 : 0
  source = "./modules/backup"

  vm_id               = module.vm.vm_id
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.common_tags

  create_vault        = var.create_backup_vault
  vault_name          = var.backup_vault_name
  existing_vault_id   = var.existing_backup_vault_id
  existing_vault_name = var.existing_backup_vault_name

  create_policy      = var.create_backup_policy
  policy_name        = var.backup_policy_name
  existing_policy_id = var.existing_backup_policy_id

  backup_timezone         = var.backup_timezone
  backup_frequency        = var.backup_frequency
  backup_time             = var.backup_time
  retention_daily_count   = var.retention_daily_count
  retention_weekly_count  = var.retention_weekly_count
  retention_monthly_count = var.retention_monthly_count

  depends_on = [module.extensions]
}

# ---------------------------------------------------------------------------
# Module: Monitoring
# ---------------------------------------------------------------------------
module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"

  vm_id               = module.vm.vm_id
  vm_name             = module.vm.vm_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.common_tags

  create_workspace      = var.create_log_workspace
  workspace_name        = var.log_workspace_name
  existing_workspace_id = var.existing_workspace_id
  log_retention_days    = var.log_retention_days

  create_alerts            = var.create_alerts
  create_action_group      = var.create_action_group
  existing_action_group_id = var.existing_action_group_id
  alert_email_addresses    = var.alert_email_addresses

  depends_on = [module.extensions]
}
