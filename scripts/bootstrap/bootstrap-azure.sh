#! /bin/bash
#=====================================================#
# Bootstrap: Azure Tenant (Bash / Linux)
#=====================================================#

# DESCRIPTION:
# Azure Tenant Bootstrap Script for Terraform Backend.
# Creates a new Entra ID Group with Contributor assignment at tenant root.
# Creates a Service Principal for CI/CD and Terraform integration, add to above group.
# Configuresa Terraform remote backend in Azure using Storage Account and Blob Container.

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
entraGroupName="Sec-RBAC-Global-Contributors"
entraGroupDesc="Security group for privileged identities to assign contributor (RBAC) role at tenant level."

# Azure: Resource Group, Storage Account, and Blob Container
location="australiaeast"
resourceGroupName="$orgPrefix-$platform-$service-$environment-rg" # Resource Group name
storageAccountName="${orgPrefix}${platform}${service}${environment}$(shuf -i 10000-99999 -n 1)" # Random suffix, max 24 characters
containerName="$orgPrefix-$platform-$service-tfstate" # Blob Container name

# Tags: Declare using associative array
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

# Function: Get tenant root management group ID.
get_tenant_root_mg(){
  root_mg_id=$(az account management-group list --query "[?displayName=='$rootMGName'].id" -o tsv)
  if [[ -z "$root_mg_id" ]]; then
    echo -e "${RED}ERROR: Tenant Root Group not found. Abort.${NC}"
    exit 1
  fi
}

# Function: Create Entra ID group for RBAC 'Contributor' at ternant root.
create_entra_group(){
  entra_group=$(az ad group create --display-name "$entraGroupName" --mail-nickname "$entraGroupName" --description "$entraGroupDesc")
  if [[ -z "$entra_group" ]]; then
    echo -e "${RED}ERROR: Failed to configure Entra group '$entraGroupName'. Abort. ${NC}"
    exit 1
  else
    # Get group ID. Assign 'Contributor' role to group at tenant root managment group.
    entra_group_id=$(az ad group show --group "$entraGroupName" --query "id" --output tsv)
    group_role_assignment=$(az role assignment create --assignee-object-id "$entra_group_id" --role Contributor --scope "$root_mg_id")
    if [[ -z "$group_role_assignment" ]]; then
      echo -e "${RED}ERROR: Failed to assign role for Entra group '$entraGroupName'. Abort. ${NC}"
      exit 1
    fi
  fi
}

# Function: Create Serivce Principal for Terraform, deployments, CI/CD etc.
create_service_principal(){
  sp=$(az ad sp create-for-rbac --name "$servicePrincipalName")
  if [[ -z "$sp" ]]; then
    echo -e "${RED}ERROR: Failed to configure Service Principal. Abort. ${NC}"
    exit 1
  else
    sp_oid=$(az ad sp show --id $(echo "$sp" | jq -r '.appId') --query "id" -o tsv)
    # Assign Service Principal to Entra group using objectID.
    memberCheck=$(az ad group member check --group "$entraGroupName" --member-id $sp_oid)
    is_member=$(echo "$memberCheck" | jq -r '.value')
    if [[ "$is_member" == "false" ]]; then
      memberAdd=$(az ad group member add --group "$entraGroupName" --member-id $sp_oid)
      # Re-Check group membership after add.
      memberCheck2=$(az ad group member check --group "$entraGroupName" --member-id $sp_oid)
      is_member2=$(echo "$memberCheck2" | jq -r '.value')
      if [[ "$is_member2" == "false" ]]; then
        echo -e "${RED}ERROR: Failed to add Service Principal to group '$entraGroupName'. Abort. ${NC}"
      fi
    fi
  fi
}


#------------------------------------------------#
# MAIN SCRIPT EXECUTION
#------------------------------------------------#

# Main: Run functions.
get_tenant_root_mg
create_entra_group
create_service_principal

# TO DO:
# rename_default_sub
# create_terraform_backend

# Results/Output.
echo -e "${YELLOW}#=============================================================#"
echo -e "${GREEN}                    Azure Bootstrap Script"
echo -e "${YELLOW}#=============================================================#"
echo
#echo -e "${YELLOW}Tenant Root Group:${NC} $root_mg_id"
echo -e "${YELLOW}[Default Subscription] ID:${NC} "
echo -e "${YELLOW}[Default Subscription] Name:${NC} "
echo
echo -e "${YELLOW}[Entra] Contributors Group:${NC} $entraGroupName"
echo 
echo -e "${YELLOW}[Service Principal] Name:${NC} $(echo "$sp" | jq -r '.displayName')"
echo -e "${YELLOW}[Service Principal] Tenant:${NC} $(echo "$sp" | jq -r '.tenant')"
echo -e "${YELLOW}[Service Principal] AppId:${NC} $(echo "$sp" | jq -r '.appId')"
echo -e "${YELLOW}[Service Principal] Secret:${NC} $(echo "$sp" | jq -r '.password')"
echo 
echo -e "${YELLOW}[Terraform] Resource Group:${NC} "
echo -e "${YELLOW}[Terraform] Storage Account:${NC} "
echo -e "${YELLOW}[Terraform] Container:${NC} "
echo
echo -e "${YELLOW}#=============================================================#"
# clear && ./scripts/bootstrap/bootstrap-azure.sh