###############################################################################
# Module: vm
# File  : variables.tf
#
# All input variables are declared here with sane defaults where possible.
# Sensitive values (passwords, keys) are marked sensitive = true so Terraform
# will redact them from plan output.
###############################################################################

# ---------------------------------------------------------------------------
# Core identity
# ---------------------------------------------------------------------------
variable "vm_name" {
  description = "The full name of the virtual machine resource in Azure."
  type        = string

  validation {
    condition     = length(var.vm_name) <= 64 && can(regex("^[a-zA-Z0-9-]+$", var.vm_name))
    error_message = "vm_name must be 1-64 characters and contain only letters, numbers, and hyphens."
  }
}

variable "computer_name" {
  description = "The hostname inside the OS.  Defaults to first 15 chars of vm_name when null."
  type        = string
  default     = null
}

variable "environment" {
  description = "Deployment environment (dev / staging / prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "cost_center" {
  description = "Cost centre code applied as a tag to every resource in this module."
  type        = string
}

variable "extra_tags" {
  description = "Any additional tags to merge with the module's base tags."
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Placement
# ---------------------------------------------------------------------------
variable "resource_group_name" {
  description = "Name of the resource group that will contain the VM and related resources."
  type        = string
}

variable "location" {
  description = "Azure region, e.g. eastus, westeurope."
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones.  Pass a single-element list to pin to a zone, empty list for no pinning."
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------
variable "subnet_id" {
  description = "Resource ID of the subnet to attach the NIC to."
  type        = string
}

variable "private_ip_address" {
  description = "Static private IP.  Leave null for DHCP allocation."
  type        = string
  default     = null
}

variable "nsg_id" {
  description = "Resource ID of the NSG to associate with the NIC.  Leave null to skip."
  type        = string
  default     = null
}

variable "create_public_ip" {
  description = "Set to true to create and attach a standard SKU public IP."
  type        = bool
  default     = false
}

variable "enable_accelerated_networking" {
  description = "Enable accelerated networking on the NIC.  Requires a supporting VM SKU."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Compute
# ---------------------------------------------------------------------------
variable "os_type" {
  description = "Operating system family.  Must be 'Windows' or 'Linux'."
  type        = string

  validation {
    condition     = contains(["Windows", "Linux"], var.os_type)
    error_message = "os_type must be 'Windows' or 'Linux'."
  }
}

variable "vm_size" {
  description = "Azure VM SKU, e.g. Standard_D4s_v5."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "license_type" {
  description = "Azure Hybrid Benefit licence type.  Set to 'Windows_Server' to use existing licences."
  type        = string
  default     = "None"
}

# ---------------------------------------------------------------------------
# OS image
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
  description = "Storage type for the OS disk.  Premium_LRS is strongly recommended for production."
  type        = string
  default     = "Premium_LRS"
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GB.  null uses the image default."
  type        = number
  default     = null
}

variable "data_disks" {
  description = "List of data disks to create and attach."
  type = list(object({
    name                 = string
    disk_size_gb         = number
    lun                  = number
    caching              = string # None, ReadOnly, ReadWrite
    storage_account_type = string # Standard_LRS, Premium_LRS, UltraSSD_LRS, etc.
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Credentials
# ---------------------------------------------------------------------------
variable "admin_username" {
  description = "Local administrator account name."
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Local administrator password.  Required for Windows VMs and password-auth Linux VMs."
  type        = string
  sensitive   = true
  default     = null
}

variable "ssh_public_key" {
  description = "SSH public key for Linux VMs.  When set, password auth is disabled."
  type        = string
  sensitive   = true
  default     = null
}

# ---------------------------------------------------------------------------
# Security
# ---------------------------------------------------------------------------
variable "enable_encryption_at_host" {
  description = "Requires 'Microsoft.Compute/EncryptionAtHost' feature to be registered on the subscription."
  type        = bool
  default     = false
}
