variable "prefix" {
  type        = string
  description = "Prefix for resource names"
}
variable "location" {
  type        = string
  description = "Azure region for resource deployment"
}
variable "vnet_cidr" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}
variable "aks_subnet_cidr" {
  type    = list(string)
  default = ["10.0.1.0/24"]
}

variable "log_analytics_sku" {
  type    = string
  default = "PerGB2018"
}

variable "log_analytics_retention_days" {
  type    = number
  default = 30
}

# Optional Component Toggles
variable "enable_acr" {
  type    = bool
  default = true
}

variable "enable_kv" {
  type    = bool
  default = true
}

variable "enable_logs" {
  type    = bool
  default = true
}

variable "acr_sku" {
  type    = string
  default = "Premium"
}

variable "acr_admin_enabled" {
  type    = bool
  default = false
}

variable "kv_sku_name" {
  type    = string
  default = "standard"
}

variable "kv_retention_days" {
  type    = number
  default = 7
}

variable "kv_purge_protection_enabled" {
  type    = bool
  default = true
}
