prefix                    = "devaks"
location                  = "eastus"
vnet_cidr                 = ["10.0.0.0/16"]
aks_subnet_cidr           = ["10.0.1.0/24"]
log_analytics_sku              = "PerGB2018"
log_analytics_retention_days   = 30

enable_acr      = true
enable_kv       = true
enable_logs     = true  
acr_sku                        = "Standard"
acr_admin_enabled              = false

kv_sku_name                    = "standard"
kv_retention_days              = 7
kv_purge_protection_enabled    = true
