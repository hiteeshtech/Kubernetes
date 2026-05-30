output "resource_groups" {
  description = "A map containing the created resource group objects."
  value       = azurerm_resource_group.this
}

output "resource_group_names" {
  description = "A map of resource group keys to their names."
  value       = { for k, v in azurerm_resource_group.this : k => v.name }
}

output "resource_group_locations" {
  description = "A map of resource group keys to their locations."
  value       = { for k, v in azurerm_resource_group.this : k => v.location }
}
