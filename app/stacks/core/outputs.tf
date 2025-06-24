# Outputs for core resources
output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = module.core.vnet_id
}

output "subnet_aks_id" {
  description = "ID of the AKS Subnet"
  value       = module.core.subnet_aks_id
}

output "acr_name" {
  description = "Name of the Azure Container Registry (if enabled)"
  value       = module.core.acr_name
}

output "key_vault_name" {
  description = "Name of the Key Vault (if enabled)"
  value       = module.core.key_vault_name
}
