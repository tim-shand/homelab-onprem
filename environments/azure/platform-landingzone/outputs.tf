#=================================================#
# Platform: Deploying Azure Platform Landing Zone.
#=================================================#

output "plz_hub_vnet_rg" {
  description = "The name of the hub VNet."
  value = try(module.plz-con-network-hub["hub"].plz_hub_vnet_rg, null)
}

output "plz_hub_vnet_name" {
  description = "The name of the hub VNet."
  value = try(module.plz-con-network-hub["hub"].plz_hub_vnet_name, null)
}
