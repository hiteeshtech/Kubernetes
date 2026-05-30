terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
}

resource "azurerm_container_registry" "this" {
  for_each = var.container_registries

  name                          = each.value.name
  resource_group_name           = each.value.resource_group_name
  location                      = each.value.location
  sku                           = each.value.sku
  admin_enabled                 = each.value.admin_enabled
  public_network_access_enabled = each.value.public_network_access_enabled
  tags                          = each.value.tags

  # Georeplication block - evaluated dynamically and conditionally
  # (Only available for Premium SKU)
  dynamic "georeplications" {
    for_each = each.value.sku == "Premium" ? each.value.georeplications : []
    content {
      location                  = georeplications.value.location
      regional_endpoint_enabled = georeplications.value.regional_endpoint_enabled
      zone_redundancy_enabled   = georeplications.value.zone_redundancy_enabled
      tags                      = georeplications.value.tags
    }
  }

  # Network rule set block - evaluated dynamically and conditionally
  # (Only available for Premium SKU)
  dynamic "network_rule_set" {
    for_each = (each.value.sku == "Premium" && each.value.network_rule_set != null) ? [each.value.network_rule_set] : []
    content {
      default_action = network_rule_set.value.default_action

      # Nested dynamic block for IP rule maps
      dynamic "ip_rule" {
        for_each = network_rule_set.value.ip_rules
        content {
          action   = ip_rule.value.action
          ip_range = ip_rule.value.ip_range
        }
      }
    }
  }
}
