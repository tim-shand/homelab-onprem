#! /bin/bash
#=====================================================#
# Bootstrap: Azure Tenant (Windows PowerShell)
#=====================================================#

# DESCRIPTION:
# Azure Tenant Bootstrap Script for Terraform Backend.
# Sets up a Terraform backend in Azure using Storage Account and Blob Container.
# It also creates a Service Principal for CI/CD and Terraform integration.

# NOTE: 
# Requires administrator privileges to run.

# USAGE:
# .\scripts\bootstrap\bootstrap-azure.sh

#------------------------------------------------#
# VARIABLES
#------------------------------------------------#

# Console Colour Config
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color / Reset

# Organization and Project Variables
orgPrefix="tjs" # Short code name for the organization.
platform="mgt" # mgt, app, inf, web, sec, dta
project="platform" # platform, app, web
service="terraform" # terraform, ansible, kubernetes, security
environment="prd" # prd, dev, tst
tagOwner="CloudOps"
tagCreator="CloudOps-Bootstrap"

# Azure: Management Groups and Subscriptions
rootMGName="Tenant Root Group" # Default Management Group name for the root management group.
platformMG="Platform" # New Management Group for the platform subscription.
workloadMG="Workload" # New Management Group for the workload subscriptions.
defaultSubNameNew="$orgPrefix-$platform-$project-$environment" # New subscription name.

# Azure: Service Principal and Entra Groups
servicePrincipalName="$orgPrefix-$platform-$service-sp" # Service Principal name
declare -A entraGroups
entraGroups[Sec-Role-Global-Contributors]="Security group for privileged Service Principals to assign contributor role at tenant level."

# Azure: Resource Group, Storage Account, and Blob Container
location="australiaeast"
resourceGroupName="$orgPrefix-$platform-$service-$environment-rg" # Resource Group name
storageAccountName="${orgPrefix}${platform}${service}${environment}$(shuf -i 10000-99999 -n 1)" # Random suffix, max 24 characters
containerName="$orgPrefix-$platform-$service-tfstate" # Blob Container name

# Tags: Declare the associative array
declare -A tags=(
    [environment]="$environment"
    [owner]="$tagOwner"
    [creator]="$tagCreator"
    [platform]="$platform"
    [project]="$project"
    [service]="$service"
    [created]="$(date +"%Y%m%d%H%M%S")"
)

#==========================================================================#
# FUNCTIONS
#==========================================================================#

# Function: Create/check Entra ID groups.
config_entra_groups(){
  local $entraGroups=$1
  for groupName in "${!entraGroups[@]}"; do
      newEntraGroup=$(az ad group create --display-name "$groupName" --mail-nickname "$groupName" --description "${entraGroups[$groupName]}" > /dev/null)
      newEntraGroupId=$(az ad group show --group "$groupName" --query "id" --output tsv)
      if [[ -n "$newEntraGroupId" ]]; then
        # Assign group as 'Contributor' to tenant root management group.
        groupRoleAssign=$(az role assignment create --assignee "$newEntraGroupId" --role Contributor --scope "$root_mg_id" > /dev/null)
        echo $groupName
      fi
  done
}

# Function: Create/Check Service Principal.
config_service_principal(){
  local $servicePrincipalName=$1
  local $root_mg_id=$2
  local $group_assign=$3
  service_principal=$(az ad sp create-for-rbac --name "$servicePrincipalName" --role "Contributor" --scopes "$root_mg_id" > /dev/null)
  memberAdd=$(az ad group member add --group "$group_assign" --member-id $service_principal_oid > /dev/null)
  echo $service_principal
}

#------------------------------------------------#
# MAIN SCRIPT EXECUTION
#------------------------------------------------#

# Get tenant root management group.
root_mg_id=$(az account management-group list --query "[?displayName=='$rootMGName'].id" -o tsv)
if [[ -n "$root_mg_id" ]]; then
  echo -e "${GREEN}INFO: Tenant Root Group found: $root_mg_id ${NC}"
else
  echo -e "${RED}ERROR:Tenant Root Group not found. Abort. ${NC}"
  exit 1
fi

# Configure Entra Groups.
entra_groups=$(config_entra_groups "$entraGroups")

# Configure Service Principal.
service_principal=$(config_service_principal "$servicePrincipalName" "$root_mg_id" "$entra_groups")
if [[ -n "$service_principal" ]]; then
  echo -e "${GREEN}INFO: Service Principal configured: $service_principal ${NC}"
else
  echo -e "${RED}ERROR: Failed to configure Service Principal. Abort. ${NC}"
  exit 1
fi
