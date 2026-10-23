###############################################################################
# Root module — variables.tf
# Aggregates inputs from all child modules into a single entry point.
###############################################################################

# ---------------------------------------------------------------------------
# Subscription / project metadata
# ---------------------------------------------------------------------------
variable "subscription_id" {
  description = "Azure Subscription ID where resources will be deployed."
  type        = string
}

variable "project_name" {
  description = "Short project name applied as a tag."
  type        = string
}

variable "cost_center" {
  description = "Cost centre code for billing attribution."
  type        = string
}

variable "extra_tags" {
  description = "Additional tags merged with the module's base tags."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------
variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

# ---------------------------------------------------------------------------
# VM core
# ---------------------------------------------------------------------------
variable "vm_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "os_type" {
  type    = string
  default = "Windows"
}

variable "vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "availability_zones" {
  type    = list(string)
  default = []
}

variable "license_type" {
  type    = string
  default = "None"
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------
variable "subnet_id" {
  type = string
}

variable "private_ip_address" {
  type    = string
  default = null
}

variable "nsg_id" {
  type    = string
  default = null
}

variable "create_public_ip" {
  type    = bool
  default = false
}

variable "enable_accelerated_networking" {
  type    = bool
  default = true
}

# ---------------------------------------------------------------------------
# Image
# ---------------------------------------------------------------------------
variable "image_publisher" {
  type    = string
  default = "MicrosoftWindowsServer"
}

variable "image_offer" {
  type    = string
  default = "WindowsServer"
}

variable "image_sku" {
  type    = string
  default = "2022-Datacenter"
}

variable "image_version" {
  type    = string
  default = "latest"
}

# ---------------------------------------------------------------------------
# Disks
# ---------------------------------------------------------------------------
variable "os_disk_type" {
  type    = string
  default = "Premium_LRS"
}

variable "os_disk_size_gb" {
  type    = number
  default = null
}

variable "data_disks" {
  type = list(object({
    name                 = string
    disk_size_gb         = number
    lun                  = number
    caching              = string
    storage_account_type = string
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Authentication
# ---------------------------------------------------------------------------
variable "admin_username" {
  type    = string
  default = "azureadmin"
}

variable "admin_password" {
  type      = string
  sensitive = true
  default   = null
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
  default   = null
}

# ---------------------------------------------------------------------------
# Security
# ---------------------------------------------------------------------------
variable "enable_encryption_at_host" {
  type    = bool
  default = false
}

# ---------------------------------------------------------------------------
# Custom Script Extension
# ---------------------------------------------------------------------------
variable "enable_custom_script" {
  type    = bool
  default = false
}

variable "script_file_uris" {
  type    = list(string)
  default = []
}

variable "script_command" {
  type    = string
  default = ""
}

variable "script_storage_account_name" {
  type      = string
  default   = null
  sensitive = true
}

variable "script_storage_account_key" {
  type      = string
  default   = null
  sensitive = true
}

# ---------------------------------------------------------------------------
# Domain Join
# ---------------------------------------------------------------------------
variable "enable_domain_join" {
  type    = bool
  default = false
}

variable "domain_name" {
  type    = string
  default = ""
}

variable "domain_ou_path" {
  type    = string
  default = ""
}

variable "domain_join_user" {
  type      = string
  default   = ""
  sensitive = true
}

variable "domain_join_password" {
  type      = string
  default   = ""
  sensitive = true
}

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------
variable "enable_backup" {
  type    = bool
  default = true
}

variable "create_backup_vault" {
  type    = bool
  default = true
}

variable "backup_vault_name" {
  type    = string
  default = "rsv-platform-prod"
}

variable "existing_backup_vault_id" {
  type    = string
  default = null
}

variable "existing_backup_vault_name" {
  type    = string
  default = null
}

variable "create_backup_policy" {
  type    = bool
  default = true
}

variable "backup_policy_name" {
  type    = string
  default = "policy-vm-daily-30d"
}

variable "existing_backup_policy_id" {
  type    = string
  default = null
}

variable "backup_timezone" {
  type    = string
  default = "UTC"
}

variable "backup_frequency" {
  type    = string
  default = "Daily"
}

variable "backup_time" {
  type    = string
  default = "23:00"
}

variable "retention_daily_count" {
  type    = number
  default = 30
}

variable "retention_weekly_count" {
  type    = number
  default = 12
}

variable "retention_monthly_count" {
  type    = number
  default = 12
}

# ---------------------------------------------------------------------------
# Monitoring
# ---------------------------------------------------------------------------
variable "enable_monitoring" {
  type    = bool
  default = true
}

variable "create_log_workspace" {
  type    = bool
  default = true
}

variable "log_workspace_name" {
  type    = string
  default = "law-platform-prod"
}

variable "existing_workspace_id" {
  type    = string
  default = null
}

variable "log_retention_days" {
  type    = number
  default = 90
}

variable "create_alerts" {
  type    = bool
  default = true
}

variable "create_action_group" {
  type    = bool
  default = true
}

variable "existing_action_group_id" {
  type    = string
  default = null
}

variable "alert_email_addresses" {
  type    = list(string)
  default = []
}
