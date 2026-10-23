###############################################################################
# Environment: prod
# File       : terraform.tfvars
#
# All secrets (admin_password, domain_join_password, etc.) are intentionally
# left out of this file.  They are injected by the pipeline as environment
# variables: TF_VAR_admin_password, TF_VAR_domain_join_password, etc.
###############################################################################

# ---- Subscription ----
subscription_id = "00000000-0000-0000-0000-000000000000" # replace with your subscription ID

# ---- Project metadata ----
project_name = "platform-infra"
cost_center  = "CC-1234"

extra_tags = {
  Owner              = "platform-engineering@example.com"
  Criticality        = "High"
  DataClassification = "Internal"
}

# ---- Resource Group ----
resource_group_name = "rg-platform-prod-eastus"
location            = "eastus"

# ---- VM ----
vm_name     = "vm-plat-prod-001"
environment = "prod"
os_type     = "Windows"
vm_size     = "Standard_D4s_v5"

availability_zones = ["1"]
license_type       = "Windows_Server" # Azure Hybrid Benefit

# ---- Network ----
# Plug in the resource IDs from your landing zone / hub-spoke deployment.
subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-networking-prod/providers/Microsoft.Network/virtualNetworks/vnet-prod-eastus/subnets/snet-servers"
nsg_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-networking-prod/providers/Microsoft.Network/networkSecurityGroups/nsg-servers-prod"

create_public_ip              = false # Always false for production servers
enable_accelerated_networking = true

# ---- Image ----
image_publisher = "MicrosoftWindowsServer"
image_offer     = "WindowsServer"
image_sku       = "2022-Datacenter"
image_version   = "latest"

# ---- Disks ----
os_disk_type    = "Premium_LRS"
os_disk_size_gb = 128

data_disks = [
  {
    name                 = "data01"
    disk_size_gb         = 256
    lun                  = 0
    caching              = "ReadOnly"
    storage_account_type = "Premium_LRS"
  },
  {
    name                 = "log01"
    disk_size_gb         = 128
    lun                  = 1
    caching              = "None"
    storage_account_type = "Premium_LRS"
  }
]

# ---- Auth (non-secret portion) ----
admin_username = "azureadmin"

# ---- Security ----
enable_encryption_at_host = true

# ---- Custom Script Extension ----
enable_custom_script = true
script_file_uris = [
  "https://sttfstate01.blob.core.windows.net/scripts/bootstrap-windows.ps1"
]
script_command = "powershell -ExecutionPolicy Unrestricted -File bootstrap-windows.ps1"

# ---- Domain Join ----
enable_domain_join = true
domain_name        = "corp.example.com"
domain_ou_path     = "OU=Servers,OU=Production,DC=corp,DC=example,DC=com"

# ---- Backup ----
enable_backup              = true
create_backup_vault        = false # Use the shared vault in prod
existing_backup_vault_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-backup-prod/providers/Microsoft.RecoveryServices/vaults/rsv-platform-prod"
existing_backup_vault_name = "rsv-platform-prod"

create_backup_policy      = false
existing_backup_policy_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-backup-prod/providers/Microsoft.RecoveryServices/vaults/rsv-platform-prod/backupPolicies/policy-vm-daily-30d"

# ---- Monitoring ----
enable_monitoring     = true
create_log_workspace  = false # Shared workspace in prod
existing_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-monitoring-prod/providers/Microsoft.OperationalInsights/workspaces/law-platform-prod"

create_alerts         = true
create_action_group   = true
alert_email_addresses = ["platform-alerts@example.com", "oncall@example.com"]
