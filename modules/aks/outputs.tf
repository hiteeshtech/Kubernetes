output "aks_clusters" {
  description = "A map containing the created AKS cluster objects."
  value       = azurerm_kubernetes_cluster.this
  sensitive   = true
}

output "aks_cluster_names" {
  description = "A map of AKS keys to cluster names."
  value       = { for k, v in azurerm_kubernetes_cluster.this : k => v.name }
}

output "aks_cluster_endpoints" {
  description = "A map of AKS keys to Kubernetes API server endpoints."
  value       = { for k, v in azurerm_kubernetes_cluster.this : k => v.kube_config[0].host }
}

output "aks_kube_configs" {
  description = "A map of AKS keys to raw kubeconfig contents."
  value       = { for k, v in azurerm_kubernetes_cluster.this : k => v.kube_config_raw }
  sensitive   = true
}

output "aks_identities" {
  description = "A map of AKS keys to their principal and tenant IDs."
  value = { for k, v in azurerm_kubernetes_cluster.this : k => {
    principal_id = try(v.identity[0].principal_id, null)
    tenant_id    = try(v.identity[0].tenant_id, null)
  } }
}

output "additional_node_pools" {
  description = "A map containing the created additional Node Pool objects."
  value       = azurerm_kubernetes_cluster_node_pool.additional
}
