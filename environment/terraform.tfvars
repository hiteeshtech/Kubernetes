# -----------------------------------------------------------------------------
# RESOURCE GROUPS CONFIGURATION
# -----------------------------------------------------------------------------
resource_groups = {
  dev = {
    name     = "rg-dev-k8s"
    location = "eastus"
    tags = {
      Environment = "Development"
      Team        = "Engineering"
      ManagedBy   = "Terraform"
    }
  }
  prod = {
    name     = "rg-prod-k8s"
    location = "eastus"
    tags = {
      Environment = "Production"
      Team        = "SRE"
      ManagedBy   = "Terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# CONTAINER REGISTRIES CONFIGURATION
# -----------------------------------------------------------------------------
container_registries = {
  # Development ACR: Standard, public access, no advanced networking/georeplication
  dev_acr = {
    name               = "acrdevhiteshk8s" # Must be globally unique, lowercase, alphanumeric only
    resource_group_key = "dev"
    sku                = "Standard"
    admin_enabled      = true
    tags = {
      Environment = "Development"
    }
  }

  # Production ACR: Premium, with Geo-Replication and strict network firewalls
  prod_acr = {
    name                          = "acrprodhiteshk8s"
    resource_group_key            = "prod"
    sku                           = "Premium" # Required for georeplications and network rule sets
    admin_enabled                 = false
    public_network_access_enabled = true

    # Geo-replication regions
    georeplications = [
      {
        location                  = "westeurope"
        regional_endpoint_enabled = true
        zone_redundancy_enabled   = true
        tags = {
          Role = "Replica"
        }
      }
    ]

    # Advanced network access rules
    network_rule_set = {
      default_action = "Deny"
      ip_rules = [
        {
          ip_range = "203.0.113.0/24" # Corporate office VPN IP range
          action   = "Allow"
        }
      ]
    }

    tags = {
      Environment = "Production"
    }
  }
}

# -----------------------------------------------------------------------------
# KUBERNETES CLUSTERS CONFIGURATION
# -----------------------------------------------------------------------------
aks_clusters = {
  # Development Cluster: Free SKU, single default node pool, no extra bells and whistles
  dev_cluster = {
    name               = "aks-dev-cluster"
    resource_group_key = "dev"
    dns_prefix         = "aksdev"
    sku_tier           = "Free"
    attach_to_acr_key  = "dev_acr" # Automatically links with the development ACR above

    default_node_pool = {
      name                = "agentpool"
      node_count          = 1
      vm_size             = "Standard_D2s_v3"
      enable_auto_scaling = false
    }

    tags = {
      Environment = "Development"
    }
  }

  # Production Cluster: Standard SKU, Auto-scaling default, multiple advanced additional pools,
  # Azure AD Integration, Key Vault, and specific ACR integration.
  prod_cluster = {
    name               = "aks-prod-cluster"
    resource_group_key = "prod"
    dns_prefix         = "aksprod"
    sku_tier           = "Standard"
    attach_to_acr_key  = "prod_acr" # Automatically links with the production ACR above

    # Default system pool
    default_node_pool = {
      name                = "systempool"
      node_count          = 3
      vm_size             = "Standard_D4s_v3"
      enable_auto_scaling = true
      min_count           = 3
      max_count           = 5
      zones               = ["1", "2", "3"]
      max_pods            = 50
    }

    # Additional specialized pools using our nested map structure
    additional_node_pools = {
      # Custom User Node Pool for general workloads
      workloadpool = {
        vm_size             = "Standard_D4s_v3"
        node_count          = 2
        enable_auto_scaling = true
        min_count           = 2
        max_count           = 10
        zones               = ["1", "2", "3"]
        node_labels = {
          role = "general-workloads"
        }
      }
      # specialized node pool with taints for high-performance GPU jobs
      gpupool = {
        vm_size             = "Standard_NC6s_v3"
        node_count          = 1
        enable_auto_scaling = false
        os_disk_size_gb     = 256
        node_labels = {
          workload = "machine-learning"
          gpu      = "nvidia"
        }
        node_taints = [
          "sku=gpu:NoSchedule"
        ]
      }
    }

    # Custom Identity (SystemAssigned in this example, but ready for UserAssigned)
    identity = {
      type = "SystemAssigned"
    }

    # Production network profile
    network_profile = {
      network_plugin    = "azure"
      network_policy    = "calico"
      dns_service_ip    = "10.2.0.10"
      service_cidr      = "10.2.0.0/16"
      outbound_type     = "loadBalancer"
      load_balancer_sku = "standard"
    }

    # Active Directory Integration (RBAC)
    azure_active_directory_rbac = {
      admin_group_object_ids = ["00000000-0000-0000-0000-000000000000"] # Replace with real AD Group Object IDs
      azure_rbac_enabled     = true
    }

    # Secrets Provider (Key Vault CSIDriver Integration)
    key_vault_secrets_provider = {
      secret_rotation_enabled  = true
      secret_rotation_interval = "5m"
    }

    tags = {
      Environment = "Production"
      Compliance  = "PCI-DSS"
    }
  }
}
