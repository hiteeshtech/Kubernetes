variable "container_registries" {
  type = map(object({
    name                          = string
    resource_group_name           = string
    location                      = string
    sku                           = optional(string, "Standard")
    admin_enabled                 = optional(bool, false)
    public_network_access_enabled = optional(bool, true)

    # Nested configurations utilizing optional attributes
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
  description = "Map of Container Registries to create with complex structures, nesting, and optional attributes."
}
