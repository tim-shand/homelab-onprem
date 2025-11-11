#==========================================#
# Platform: Connectivity - Network (Hub)
#==========================================#

# Module outputs, to be passed to other modules.

output "plz_hub_vnet_rg" {
  value = azurerm_virtual_network.plz_con_hub_vnet.resource_group_name
  description = "Resource Group of hub VNet."
}

output "plz_hub_vnet_name" {
  value = azurerm_virtual_network.plz_con_hub_vnet.name
  description = "Name of hub VNet."
}

output "plz_hub_vnet_address_space" {
  value = azurerm_virtual_network.plz_con_hub_vnet.address_space
  description = "The IP address space of the hub VNet."
}
