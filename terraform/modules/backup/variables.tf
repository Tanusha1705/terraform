###############################################################################
# Module: backup — variables.tf
###############################################################################

variable "vm_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

# ---------------------------------------------------------------------------
# Vault
# ---------------------------------------------------------------------------
variable "create_vault" {
  description = "Set to true to create a new Recovery Services Vault."
  type        = bool
  default     = true
}

variable "vault_name" {
  type    = string
  default = "rsv-platform-prod"
}

variable "existing_vault_id" {
  description = "Resource ID of an existing vault — used when create_vault = false."
  type        = string
  default     = null
}

variable "existing_vault_name" {
  description = "Name of an existing vault — used when create_vault = false."
  type        = string
  default     = null
}

variable "soft_delete_enabled" {
  type    = bool
  default = true
}

variable "vault_immutability" {
  type    = string
  default = "Unlocked"

  validation {
    condition     = contains(["Locked", "Unlocked", "Disabled"], var.vault_immutability)
    error_message = "vault_immutability must be Locked, Unlocked, or Disabled."
  }
}

# ---------------------------------------------------------------------------
# Policy
# ---------------------------------------------------------------------------
variable "create_policy" {
  type    = bool
  default = true
}

variable "policy_name" {
  type    = string
  default = "policy-vm-daily-30d"
}

variable "existing_policy_id" {
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

variable "retention_weekly_weekdays" {
  type    = list(string)
  default = ["Sunday"]
}

variable "retention_monthly_count" {
  type    = number
  default = 12
}

variable "retention_monthly_weekdays" {
  type    = list(string)
  default = ["Sunday"]
}

variable "retention_monthly_weeks" {
  type    = list(string)
  default = ["First"]
}
