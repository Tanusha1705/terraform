###############################################################################
# Module: vm
# Purpose: Provisions an Azure Windows/Linux Virtual Machine along with its
#          network interface card and optional public IP.  Everything you need
#          to get a VM on the wire — nothing more, nothing less.
#
# Author : Platform Engineering Team
# Version: 1.0.0
###############################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.85.0, < 4.0.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Local helpers — derive sensible defaults from the variables so callers
# don't have to repeat themselves in every call site.
# ---------------------------------------------------------------------------
locals {
  # If the caller did not supply a custom computer name we fall back to the
  # first 15 characters of vm_name (Windows NETBIOS limit).
  computer_name = coalesce(var.computer_name, substr(var.vm_name, 0, 15))

  # Build a map of tags that are always present, then merge caller extras.
  base_tags = {
    ManagedBy   = "Terraform"
    Module      = "vm"
    Environment = var.environment
    CostCenter  = var.cost_center
  }
  all_tags = merge(local.base_tags, var.extra_tags)

  # SSH keys map for Linux VMs
  ssh_keys = var.ssh_public_key != null ? { (var.admin_username) = var.ssh_public_key } : {}
}

# ---------------------------------------------------------------------------
# Public IP  (optional — only created when var.create_public_ip == true)
# ---------------------------------------------------------------------------
resource "azurerm_public_ip" "this" {
  count = var.create_public_ip ? 1 : 0

  name                = "${var.vm_name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones
  tags                = local.all_tags
}

# ---------------------------------------------------------------------------
# Network Interface Card
# ---------------------------------------------------------------------------
resource "azurerm_network_interface" "this" {
  name                = "${var.vm_name}-nic"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.all_tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address != null ? "Static" : "Dynamic"
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.this[0].id : null
  }

  # Accelerated networking gives significantly better throughput on larger SKUs.
  enable_accelerated_networking = var.enable_accelerated_networking
}

# ---------------------------------------------------------------------------
# Associate the NIC with the supplied NSG (if one was given)
# ---------------------------------------------------------------------------
resource "azurerm_network_interface_security_group_association" "this" {
  count = var.nsg_id != null ? 1 : 0

  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = var.nsg_id
}

# ---------------------------------------------------------------------------
# Windows Virtual Machine
# ---------------------------------------------------------------------------
resource "azurerm_windows_virtual_machine" "this" {
  count = var.os_type == "Windows" ? 1 : 0

  name                  = var.vm_name
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.vm_size
  computer_name         = local.computer_name
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.this.id]
  license_type          = var.license_type # "Windows_Server" for Azure Hybrid Benefit
  zone                  = length(var.availability_zones) > 0 ? var.availability_zones[0] : null
  tags                  = local.all_tags

  # ---- OS Disk ----
  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  # ---- Marketplace image ----
  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  # ---- Identity — system-assigned so extensions can talk to Azure APIs ----
  identity {
    type = "SystemAssigned"
  }

  # ---- Boot diagnostics — use managed storage so no SA required ----
  boot_diagnostics {}

  # ---- Patching policy ----
  patch_mode                                             = "AutomaticByPlatform"
  provision_vm_agent                                     = true
  enable_automatic_updates                               = true
  bypass_platform_safety_checks_on_user_schedule_enabled = false

  # Encryption at host requires a feature flag on the subscription — only
  # enable if the caller has done that registration step.
  encryption_at_host_enabled = var.enable_encryption_at_host
}

# ---------------------------------------------------------------------------
# Linux Virtual Machine
# ---------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "this" {
  count = var.os_type == "Linux" ? 1 : 0

  name                            = var.vm_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = var.vm_size
  computer_name                   = local.computer_name
  admin_username                  = var.admin_username
  disable_password_authentication = var.ssh_public_key != null ? true : false
  admin_password                  = var.ssh_public_key == null ? var.admin_password : null
  network_interface_ids           = [azurerm_network_interface.this.id]
  zone                            = length(var.availability_zones) > 0 ? var.availability_zones[0] : null
  tags                            = local.all_tags

  dynamic "admin_ssh_key" {
    for_each = local.ssh_keys
    content {
      username   = admin_ssh_key.key
      public_key = admin_ssh_key.value
    }
  }

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {}

  encryption_at_host_enabled = var.enable_encryption_at_host
}

# ---------------------------------------------------------------------------
# Data disks  (optional — driven by var.data_disks list)
# ---------------------------------------------------------------------------
resource "azurerm_managed_disk" "data" {
  for_each = { for d in var.data_disks : d.name => d }

  name                 = "${var.vm_name}-${each.key}"
  resource_group_name  = var.resource_group_name
  location             = var.location
  storage_account_type = each.value.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = each.value.disk_size_gb
  tags                 = local.all_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each = { for d in var.data_disks : d.name => d }

  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = var.os_type == "Windows" ? azurerm_windows_virtual_machine.this[0].id : azurerm_linux_virtual_machine.this[0].id
  lun                = each.value.lun
  caching            = each.value.caching
}
