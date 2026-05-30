terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

resource "azurerm_kubernetes_cluster" "this" {
  for_each = var.aks_clusters

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  dns_prefix          = each.value.dns_prefix
  kubernetes_version  = each.value.kubernetes_version
  sku_tier            = each.value.sku_tier
  tags                = each.value.tags

  default_node_pool {
    name                 = each.value.default_node_pool.name
    node_count           = each.value.default_node_pool.node_count
    vm_size              = each.value.default_node_pool.vm_size
    os_disk_size_gb      = each.value.default_node_pool.os_disk_size_gb
    os_disk_type         = each.value.default_node_pool.os_disk_type
    auto_scaling_enabled = each.value.default_node_pool.enable_auto_scaling
    min_count            = each.value.default_node_pool.min_count
    max_count            = each.value.default_node_pool.max_count
    vnet_subnet_id       = each.value.default_node_pool.vnet_subnet_id
    zones                = each.value.default_node_pool.zones
    max_pods             = each.value.default_node_pool.max_pods
    node_labels          = each.value.default_node_pool.node_labels
  }

  # 1. Identity configuration - Dynamic block
  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.type == "UserAssigned" ? identity.value.user_assigned_identity_ids : null
    }
  }

  # 2. Network profile configuration - Dynamic block
  dynamic "network_profile" {
    for_each = each.value.network_profile != null ? [each.value.network_profile] : []
    content {
      network_plugin    = network_profile.value.network_plugin
      network_policy    = network_profile.value.network_policy
      dns_service_ip    = network_profile.value.dns_service_ip
      service_cidr      = network_profile.value.service_cidr
      outbound_type     = network_profile.value.outbound_type
      load_balancer_sku = network_profile.value.load_balancer_sku
    }
  }

  # 3. Ingress Application Gateway - Dynamic block conditional on enabled
  dynamic "ingress_application_gateway" {
    for_each = (each.value.ingress_application_gateway != null && try(each.value.ingress_application_gateway.enabled, false)) ? [each.value.ingress_application_gateway] : []
    content {
      gateway_id   = ingress_application_gateway.value.gateway_id
      gateway_name = ingress_application_gateway.value.gateway_name
      subnet_id    = ingress_application_gateway.value.subnet_id
    }
  }

  # 4. Azure AD RBAC - Dynamic block conditional on configuration presence
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = each.value.azure_active_directory_rbac != null ? [each.value.azure_active_directory_rbac] : []
    content {
      azure_rbac_enabled     = azure_active_directory_role_based_access_control.value.azure_rbac_enabled
      admin_group_object_ids = azure_active_directory_role_based_access_control.value.admin_group_object_ids
      tenant_id              = azure_active_directory_role_based_access_control.value.tenant_id
    }
  }

  # 5. Key Vault Secrets Provider - Dynamic block conditional on configuration presence
  dynamic "key_vault_secrets_provider" {
    for_each = each.value.key_vault_secrets_provider != null ? [each.value.key_vault_secrets_provider] : []
    content {
      secret_rotation_enabled  = key_vault_secrets_provider.value.secret_rotation_enabled
      secret_rotation_interval = key_vault_secrets_provider.value.secret_rotation_interval
    }
  }
}

# local flattening logic:
# Converts a double-nested map of aks_clusters[k].additional_node_pools[p] 
# into a single flat map of clusterKey_poolKey => poolObject so for_each can run safely.
locals {
  flat_node_pools = merge([
    for cluster_key, cluster_val in var.aks_clusters : {
      for pool_key, pool_val in cluster_val.additional_node_pools :
      "${cluster_key}_${pool_key}" => merge(pool_val, {
        cluster_key = cluster_key
        pool_name   = pool_key
      })
    }
  ]...)
}

resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = local.flat_node_pools

  kubernetes_cluster_id = azurerm_kubernetes_cluster.this[each.value.cluster_key].id
  name                  = each.value.pool_name
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  auto_scaling_enabled  = each.value.enable_auto_scaling
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  os_type               = each.value.os_type
  os_disk_size_gb       = each.value.os_disk_size_gb
  vnet_subnet_id        = each.value.vnet_subnet_id
  zones                 = each.value.zones
  max_pods              = each.value.max_pods
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
}
