terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. Calling the Resource Groups Child Module
module "resource_groups" {
  source          = "../modules/resource_group"
  resource_groups = var.resource_groups
}

# 2. Calling the Azure Container Registries Child Module
module "container_registries" {
  source = "../modules/acr"

  container_registries = {
    for k, v in var.container_registries : k => merge(v, {
      resource_group_name = module.resource_groups.resource_groups[v.resource_group_key].name
      location            = module.resource_groups.resource_groups[v.resource_group_key].location
    })
  }
}

# 3. Calling the Azure Kubernetes Service Child Module
module "aks_clusters" {
  source = "../modules/aks"

  aks_clusters = {
    for k, v in var.aks_clusters : k => merge(v, {
      resource_group_name = module.resource_groups.resource_groups[v.resource_group_key].name
      location            = module.resource_groups.resource_groups[v.resource_group_key].location
    })
  }
}

# 4. Root Integration: AKS to ACR Pull Role Assignment
locals {
  aks_acr_attachments = {
    for k, v in var.aks_clusters : k => {
      aks_principal_id = module.aks_clusters.aks_identities[k].principal_id
      acr_id           = module.container_registries.acr_ids[v.attach_to_acr_key]
    }
    if v.attach_to_acr_key != null && lookup(var.container_registries, v.attach_to_acr_key, null) != null
  }
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  for_each = local.aks_acr_attachments

  principal_id                     = each.value.aks_principal_id
  role_definition_name             = "AcrPull"
  scope                            = each.value.acr_id
  skip_service_principal_aad_check = true
}
