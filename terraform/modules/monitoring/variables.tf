###############################################################################
# Module: monitoring — variables.tf
###############################################################################

variable "vm_id" {
  type = string
}

variable "vm_name" {
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
# Log Analytics Workspace
# ---------------------------------------------------------------------------
variable "create_workspace" {
  type    = bool
  default = true
}

variable "workspace_name" {
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

# ---------------------------------------------------------------------------
# Alerts
# ---------------------------------------------------------------------------
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
  description = "List of email addresses to receive alert notifications."
  type        = list(string)
  default     = []
}
