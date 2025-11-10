#=================================================#
# Platform: Deploying Azure Platform Landing Zone.
#=================================================#

# Deploy resources via modules. 

module "plz-gov-management-groups" {
  source = "../../../tfmodules/plz-gov-management-groups"
  core_management_group_display_name = var.core_management_group_display_name
  core_management_group_id = var.core_management_group_id
  subscription_id = var.subscription_id
  naming = var.naming # Get from TFVARS file.
}

module "plz-con-network-hub" {
  source = "../../../tfmodules/plz-con-network-hub"
  for_each = var.enable_plz_hubvnet ? { "hub" = true } : {}
  location = var.location # Get from TFVARS file.
  naming = var.naming # Get from TFVARS file.
  tags = var.tags # Get from TFVARS file.
  vnet_space = "10.50.0.0/22" # Allows 4x /24 subnets.
  subnet_space = "10.50.0.0/24" # Default subnet address space.
}

module "plz-log-monitor-diagnostics" {
  source = "../../../tfmodules/plz-log-monitor-diagnostics"
  for_each = var.enable_plz_logging ? { "log" = true } : {}
  location = var.location # Get from TFVARS file.
  naming = var.naming # Get from TFVARS file.
  tags = var.tags # Get from TFVARS file.
}
