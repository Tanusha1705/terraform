###############################################################################
# Module: monitoring
# Purpose: Wires up the full Azure monitoring stack for a VM:
#   - Log Analytics Workspace (optional creation or use existing)
#   - Data Collection Rule + DCR Association (tells AMA what to collect)
#   - Diagnostic Settings on the VM (Activity log, metrics)
#   - Azure Monitor alert rules for CPU, memory, and disk
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
# Log Analytics Workspace
# ---------------------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "this" {
  count = var.create_workspace ? 1 : 0

  name                = var.workspace_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

locals {
  workspace_id          = var.create_workspace ? azurerm_log_analytics_workspace.this[0].id : var.existing_workspace_id
  workspace_resource_id = local.workspace_id # alias for clarity in DCR
}

# ---------------------------------------------------------------------------
# Data Collection Rule
#   Defines WHICH performance counters and event logs AMA will collect.
# ---------------------------------------------------------------------------
resource "azurerm_monitor_data_collection_rule" "this" {
  name                = "${var.vm_name}-dcr"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  destinations {
    log_analytics {
      workspace_resource_id = local.workspace_resource_id
      name                  = "destination-log-analytics"
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf", "Microsoft-Event"]
    destinations = ["destination-log-analytics"]
  }

  data_sources {
    # Windows / Linux performance counters — covers the most common OS metrics.
    performance_counter {
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor(_Total)\\% Processor Time",
        "\\Memory\\% Committed Bytes In Use",
        "\\Memory\\Available MBytes",
        "\\LogicalDisk(_Total)\\% Disk Time",
        "\\LogicalDisk(_Total)\\Disk Transfers/sec",
        "\\LogicalDisk(_Total)\\Disk Read Bytes/sec",
        "\\LogicalDisk(_Total)\\Disk Write Bytes/sec",
        "\\Network Interface(*)\\Bytes Total/sec",
      ]
      name = "perfCounters"
    }

    # Windows Event Log — capture System and Application errors and warnings.
    windows_event_log {
      streams = ["Microsoft-Event"]
      x_path_queries = [
        "System!*[System[(Level=1 or Level=2 or Level=3)]]",
        "Application!*[System[(Level=1 or Level=2)]]",
      ]
      name = "windowsEventLogs"
    }
  }
}

# ---------------------------------------------------------------------------
# Associate the DCR with the VM
# ---------------------------------------------------------------------------
resource "azurerm_monitor_data_collection_rule_association" "this" {
  name                    = "${var.vm_name}-dcr-assoc"
  target_resource_id      = var.vm_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.this.id
  description             = "Associates the DCR with the VM so AMA knows where to send data."
}

# ---------------------------------------------------------------------------
# Diagnostic Settings on the VM itself
# ---------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "vm" {
  name                       = "${var.vm_name}-diag"
  target_resource_id         = var.vm_id
  log_analytics_workspace_id = local.workspace_id

  # VM resource type exposes "allMetrics" but no log categories.
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# ---------------------------------------------------------------------------
# Action Group — sends alerts to email / webhook / Teams
# ---------------------------------------------------------------------------
resource "azurerm_monitor_action_group" "this" {
  count = var.create_action_group ? 1 : 0

  name                = "${var.vm_name}-ag"
  resource_group_name = var.resource_group_name
  short_name          = "vmAlerts"
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = { for idx, email in var.alert_email_addresses : idx => email }
    content {
      name                    = "email-${email_receiver.key}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }
}

# ---------------------------------------------------------------------------
# Alert: CPU > 90% for 5 minutes
# ---------------------------------------------------------------------------
resource "azurerm_monitor_metric_alert" "cpu" {
  count = var.create_alerts ? 1 : 0

  name                = "${var.vm_name}-alert-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [var.vm_id]
  description         = "VM CPU utilisation exceeded 90% for 5 consecutive minutes."
  severity            = 2 # Warning
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = var.create_action_group ? azurerm_monitor_action_group.this[0].id : var.existing_action_group_id
  }
}

# ---------------------------------------------------------------------------
# Alert: Available memory < 500 MB
# ---------------------------------------------------------------------------
resource "azurerm_monitor_metric_alert" "memory" {
  count = var.create_alerts ? 1 : 0

  name                = "${var.vm_name}-alert-mem"
  resource_group_name = var.resource_group_name
  scopes              = [var.vm_id]
  description         = "VM available memory dropped below 500 MB."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 524288000 # 500 MB in bytes
  }

  action {
    action_group_id = var.create_action_group ? azurerm_monitor_action_group.this[0].id : var.existing_action_group_id
  }
}
