resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  name_suffix_kv = "${var.prefix}-${random_string.suffix.result}"
  name_suffix_acr = "${var.prefix}${random_string.suffix.result}"
}


resource "azurerm_resource_group" "core" {
  name     = "${var.prefix}-core-rg"
  location = var.location
}

resource "azurerm_virtual_network" "hub" {
  name                = "${var.prefix}-vnet"
  address_space       = var.vnet_cidr
  location            = var.location
  resource_group_name = azurerm_resource_group.core.name
}

resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = var.aks_subnet_cidr
}

resource "azurerm_network_security_group" "aks_nsg" {
  name                = "${var.prefix}-aks-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.core.name
}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "${var.prefix}-logs"
  count               = var.enable_logs ? 1 : 0
  location            = var.location
  resource_group_name = azurerm_resource_group.core.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_days
}

resource "azurerm_container_registry" "acr" {
  name = "${local.name_suffix_acr}acr"
  count                = var.enable_acr ? 1 : 0
  resource_group_name      = azurerm_resource_group.core.name
  location                 = var.location
  sku                      = var.acr_sku
  admin_enabled            = var.acr_admin_enabled
}

resource "azurerm_key_vault" "kv" {
  name                        = "${local.name_suffix_kv}-kv"
  count                        = var.enable_kv ? 1 : 0
  location                    = var.location
  resource_group_name         = azurerm_resource_group.core.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = var.kv_sku_name
  soft_delete_retention_days  = var.kv_retention_days
  purge_protection_enabled    = var.kv_purge_protection_enabled
}

data "azurerm_client_config" "current" {}
