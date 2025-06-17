module "core" {
  source = "../../modules/core"

  prefix            = var.prefix
  location          = var.location
  vnet_cidr         = var.vnet_cidr
  aks_subnet_cidr   = var.aks_subnet_cidr
  log_analytics_sku = var.log_analytics_sku
  log_analytics_retention_days = var.log_analytics_retention_days
  enable_acr = var.enable_acr
  enable_kv = var.enable_kv
  enable_logs = var.enable_logs
  acr_sku = var.acr_sku
  acr_admin_enabled = var.acr_admin_enabled
  kv_sku_name = var.kv_sku_name
  kv_retention_days = var.kv_retention_days
  kv_purge_protection_enabled = var.kv_purge_protection_enabled
}