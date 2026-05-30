output "container_registries" {
  description = "A map containing the created container registry objects."
  value       = azurerm_container_registry.this
}

output "acr_login_servers" {
  description = "A map of container registry keys to their login server URLs."
  value       = { for k, v in azurerm_container_registry.this : k => v.login_server }
}

output "acr_ids" {
  description = "A map of container registry keys to their resource IDs."
  value       = { for k, v in azurerm_container_registry.this : k => v.id }
}
