output "resource_groups" {
  description = "Detailed list of resource groups created by the module."
  value       = module.resource_groups.resource_groups
}

output "container_registries" {
  description = "Detailed list of Azure Container Registries created by the module."
  value       = module.container_registries.container_registries
}

output "acr_login_servers" {
  description = "A map of registry keys to their login server URLs."
  value       = module.container_registries.acr_login_servers
}

output "aks_clusters" {
  description = "Detailed list of Azure Kubernetes Service clusters created by the module."
  value       = module.aks_clusters.aks_clusters
  sensitive   = true
}

output "aks_endpoints" {
  description = "A map of AKS keys to their API server endpoints."
  value       = module.aks_clusters.aks_cluster_endpoints
}
