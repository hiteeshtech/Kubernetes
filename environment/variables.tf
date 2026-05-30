variable "resource_groups" {
  type = map(object({
    name     = string
    location = string
    tags     = optional(map(string), {})
  }))
  description = "Map of resource groups to be created."
  default     = {}
}

variable "container_registries" {
  type = map(object({
    name                          = string
    resource_group_key            = string # Reference to the resource_groups map key
    sku                           = optional(string, "Standard")
    admin_enabled                 = optional(bool, false)
    public_network_access_enabled = optional(bool, true)

    georeplications = optional(list(object({
      location                  = string
      regional_endpoint_enabled = optional(bool, true)
      zone_redundancy_enabled   = optional(bool, false)
      tags                      = optional(map(string), {})
    })), [])

    network_rule_set = optional(object({
      default_action = optional(string, "Allow")
      ip_rules = optional(list(object({
        ip_range = string
        action   = optional(string, "Allow")
      })), [])
    }), null)

    tags = optional(map(string), {})
  }))
  description = "Map of container registries to be created."
  default     = {}
}

variable "aks_clusters" {
  type = map(object({
    name               = string
    resource_group_key = string # Reference to the resource_groups map key
    dns_prefix         = string
    kubernetes_version = optional(string, null)
    sku_tier           = optional(string, "Free")

    default_node_pool = object({
      name                 = optional(string, "default")
      node_count           = optional(number, 1)
      vm_size              = optional(string, "Standard_D2s_v3")
      os_disk_size_gb      = optional(number, 30)
      os_disk_type         = optional(string, "Managed")
      enable_auto_scaling  = optional(bool, false)
      min_count            = optional(number, null)
      max_count            = optional(number, null)
      vnet_subnet_id       = optional(string, null)
      zones                = optional(list(string), [])
      max_pods             = optional(number, 30)
      node_labels          = optional(map(string), {})
    })

    additional_node_pools = optional(map(object({
      vm_size             = string
      node_count          = optional(number, 1)
      enable_auto_scaling = optional(bool, false)
      min_count           = optional(number, null)
      max_count           = optional(number, null)
      os_type             = optional(string, "Linux")
      os_disk_size_gb     = optional(number, 128)
      vnet_subnet_id      = optional(string, null)
      zones               = optional(list(string), [])
      max_pods            = optional(number, 30)
      node_labels         = optional(map(string), {})
      node_taints         = optional(list(string), [])
    })), {})

    identity = optional(object({
      type                      = string
      user_assigned_identity_ids = optional(list(string), [])
    }), { type = "SystemAssigned" })

    network_profile = optional(object({
      network_plugin    = optional(string, "azure")
      network_policy    = optional(string, null)
      dns_service_ip    = optional(string, "10.0.0.10")
      service_cidr      = optional(string, "10.0.0.0/16")
      outbound_type     = optional(string, "loadBalancer")
      load_balancer_sku = optional(string, "standard")
    }), {})

    ingress_application_gateway = optional(object({
      enabled      = bool
      gateway_id   = optional(string, null)
      gateway_name = optional(string, null)
      subnet_id    = optional(string, null)
    }), null)

    azure_active_directory_rbac = optional(object({
      tenant_id              = optional(string, null)
      admin_group_object_ids = optional(list(string), [])
      azure_rbac_enabled     = optional(bool, true)
    }), null)

    key_vault_secrets_provider = optional(object({
      secret_rotation_enabled  = optional(bool, false)
      secret_rotation_interval = optional(string, "2m")
    }), null)

    # Attach this cluster to a specific ACR for AcrPull permission
    attach_to_acr_key = optional(string, null)

    tags = optional(map(string), {})
  }))
  description = "Map of AKS clusters to be created."
  default     = {}
}
