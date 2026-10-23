###############################################################################
# Module: extensions — variables.tf
###############################################################################

variable "vm_id" {
  description = "Resource ID of the virtual machine."
  type        = string
}

variable "vm_principal_id" {
  description = "System-assigned managed identity principal ID — used by AMA for auth."
  type        = string
}

variable "os_type" {
  description = "Windows or Linux."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all extensions."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Custom Script Extension
# ---------------------------------------------------------------------------
variable "enable_custom_script" {
  type    = bool
  default = false
}

variable "script_file_uris" {
  description = "List of script blob URIs to download before executing."
  type        = list(string)
  default     = []
}

variable "script_command" {
  description = "Command to execute after all files have been downloaded."
  type        = string
  default     = ""
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
  description = "FQDN of the Active Directory domain, e.g. corp.example.com"
  type        = string
  default     = ""
}

variable "domain_ou_path" {
  description = "LDAP OU path to place the computer account in."
  type        = string
  default     = ""
}

variable "domain_join_user" {
  description = "UPN or SAM of the account that has rights to join computers to the domain."
  type        = string
  default     = ""
  sensitive   = true
}

variable "domain_join_password" {
  type      = string
  default   = ""
  sensitive = true
}

# ---------------------------------------------------------------------------
# Monitoring
# ---------------------------------------------------------------------------
variable "enable_monitoring" {
  description = "Set to true to deploy AMA and the Dependency Agent."
  type        = bool
  default     = true
}
