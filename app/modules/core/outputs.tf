output "vnet_id" {
  value = azurerm_virtual_network.hub.id
}

output "subnet_aks_id" {
  value = azurerm_subnet.aks.id
}

output "log_analytics_id" {
  value = try(azurerm_log_analytics_workspace.logs[0].id, null)
}

output "acr_id" {
  value = try(azurerm_container_registry.acr[0].id, null)
}

output "key_vault_id" {
  value = try(azurerm_key_vault.kv[0].id, null)
}

output "acr_name" {
  value = try(azurerm_container_registry.acr[0].name, null)
}

output "key_vault_name" {
  value = try(azurerm_key_vault.kv[0].name, null)
}
