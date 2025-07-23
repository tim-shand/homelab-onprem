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
keyvaultName="$orgPrefix-$platform-$project-kv" # Keyvault name

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
    echo -e "${RED}FATAL: Tenant Root Group not found. Abort.${NC}"
    exit 1
  fi
}

# Function: Convert tags to string form.
convert_tags(){
  # Space-separated tags: key[=value] [key[=value] ...]. Use "" to clear existing tags.
  # Convert associative array to tag string.
  tag_string=""
  for key in "${!tags[@]}"; do
    tag_string+="$key=${tags[$key]} "
  done
  tag_string=${tag_string::-1}
}

# Function: Get tenant root management group ID.
rename_default_sub(){
  # Get the default subscription ID.
  default_sub_id=$(az account list --query "[?isDefault].id" -o tsv)
  if [[ -z "$default_sub_id" ]]; then
    echo -e "${RED}FATAL: Unable to obtain default subscription. Abort.${NC}"
    exit 1
  else
    rename_sub=$(az account subscription rename --id "$default_sub_id" --name "$defaultSubNameNew" --only-show-errors)
    if [[ -z "$rename_sub" ]]; then
      echo -e "${RED}WARNING: Unable to rename default subscription. Skip.${NC}"
    fi
  fi
}

# Function: Create Entra ID group for RBAC 'Contributor' at ternant root.
create_entra_group(){
  entra_group=$(az ad group create --display-name "$entraGroupName" --mail-nickname "$entraGroupName" \
    --description "$entraGroupDesc" --only-show-errors)
  if [[ -z "$entra_group" ]]; then
    echo -e "${RED}FATAL: Failed to configure Entra group '$entraGroupName'. Abort. ${NC}"
    exit 1
  else
    # Get group ID. Assign 'Contributor' role to group at tenant root managment group.
    entra_group_id=$(az ad group show --group "$entraGroupName" --query "id" --output tsv)
    group_role_assignment=$(az role assignment create --assignee-object-id "$entra_group_id" --role Contributor --scope "$root_mg_id" --only-show-errors)
    if [[ -z "$group_role_assignment" ]]; then
      echo -e "${RED}FATAL: Failed to assign required role for Entra group '$entraGroupName'. Please investigate or assign manually. ${NC}"
      exit 1
    fi
    # Assign current logged in user as member.
    currentUserAdd=$(az ad group member add --group "$entraGroupName" --member-id "$(az ad signed-in-user show --query id --output tsv)")
    currentUserCheck=$(az ad group member check --group "$entraGroupName" --member-id "$(az ad signed-in-user show --query id --output tsv)")
    if [[ "$currentUserCheck" == "false" ]]; then
        echo -e "${RED}ERROR: Failed to add current user to group '$entraGroupName'. Please investigate or assign manually. Skip.${NC}"
        exit 1
    fi
  fi
}

# Function: Create Serivce Principal for Terraform, deployments, CI/CD etc.
create_service_principal(){
  sp=$(az ad sp create-for-rbac --name "$servicePrincipalName" --only-show-errors)
  if [[ -z "$sp" ]]; then
    echo -e "${RED}FATAL: Failed to configure required Service Principal. Please investigate or create manually. ${NC}"
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
        echo -e "${RED}FATAL: Failed to add Service Principal to group '$entraGroupName'. Please investigate or assign manually. ${NC}"
        exit 1
      fi
    fi
  fi
}

# Function: Deploy resources for Terraform backend.
deploy_terraform_backend(){
  resource_group=$(az group create --name "$resourceGroupName" --location $location --tags $tag_string)
  if [[ -z "$resource_group" ]]; then
    echo -e "${RED}FATAL: Failed create Resource Group '$resourceGroupName'. Please investigate or create manually.${NC}"
    exit 1
  else
    echo -e "${GREEN}--- Created Resource Group ($(echo $resource_group | jq -r '.name'))...${NC}"
    # Proceed to create Storage Account.
    storage_account=$(az storage account create --name $storageAccountName --resource-group "$resourceGroupName" --access-tier Hot --tags $tag_string --sku Standard_LRS)
    if [[ -z "$storage_account" ]]; then
      echo -e "${RED}FATAL: Failed create required Storage Account '$storageAccountName'. Please investigate or create manually.${NC}"
      exit 1
    else
      echo -e "${GREEN}--- Created Storage Account ($(echo $storage_account | jq -r '.name'))...${NC}"
      # Proceed with creating Container.
      container_created=$(az storage container create --name $containerName --account-name "$(echo $storage_account | jq -r '.name')" --auth-mode login)
      if [[ -z "$container_created" ]]; then
        echo -e "${RED}FATAL: Failed to create Storage Container '$containerName'. Please investigate or create manually.${NC}"
        exit 1
      else
        if [[ $(echo $container_created | jq -r '.created') == 'true' ]]; then
          container=$(az storage container show --name "$containerName" --account-name "$(echo $storage_account | jq -r '.name')" --auth-mode login)
          echo -e "${GREEN}--- Created Storage Container ($(echo $container | jq -r '.name'))...${NC}."
        else
          echo -e "${GREEN}--- Storage Container ($(echo $container | jq -r '.name')) already exists...${NC}."
          container=$containerName
        fi
      fi
    fi

    # Proceed with KeyVault.
    key_vault_check=$(az keyvault show --name "$keyvaultName")
    if [[ -z "$key_vault_check" ]]; then
      # Create Keyvault.
      key_vault=$(az keyvault create --name "$keyvaultName" --resource-group "$resourceGroupName" --location $location --tags $tag_string)
      if [[ -z "$key_vault" ]]; then
        echo -e "${RED}ERROR: Failed to create Key Vault '$keyvaultName'. Please investigate or create manually. Skip.${NC}"
      else
        echo -e "${GREEN}--- Created Key Vault ($(echo $key_vault | jq -r '.name'))...${NC}"
        # Create role assignment.
        kv_role_assignment=$(az role assignment create --assignee-object-id "$entra_group_id" \
          --role "Key Vault Secrets Officer" --scope "$(echo $key_vault | jq -r '.id')" --only-show-errors)
        kv_role_assignment_check="$(echo $kv_role_assignment | jq -r '.roleDefinitionName')"
        if [[ $(echo $kv_role_assignment | jq -r '.roleDefinitionName') == 'Key Vault Secrets Officer' ]]; then
          echo -e "${GREEN}--- Role 'Key Vault Secrets Officer' assigned to Key Vault '$keyvaultName'...${NC}"
          # Add Service Principal secret to Keyvault.
          secret_add=$(az keyvault secret set --name "$(echo "$sp" | jq -r '.displayName')" --vault-name "$keyvaultName" --value "$(echo "$sp" | jq -r '.password')")
        else
          echo -e "${RED}ERROR: Failed to assign 'Key Vault Secrets Officer' role to Key Vault '$keyvaultName'. Please investigate or create manually. Skip.${NC}"
        fi
      fi
    else
      echo -e "${GREEN}--- Key Vault '$keyvaultName' already exists. Skip.${NC}"
      # Create role assignment.
      kv_role_assignment=$(az role assignment create --assignee-object-id "$entra_group_id" \
        --role "Key Vault Secrets Officer" --scope "$(echo $key_vault_check | jq -r '.id')" --only-show-errors)
      kv_role_assignment_check="$(echo $kv_role_assignment | jq -r '.roleDefinitionName')"
      if [[ $(echo $kv_role_assignment | jq -r '.roleDefinitionName') == 'Key Vault Secrets Officer' ]]; then
        echo -e "${GREEN}--- Role 'Key Vault Secrets Officer' assigned to Key Vault '$keyvaultName'...${NC}"
        # Add Service Principal secret to Keyvault.
        secret_add=$(az keyvault secret set --name "$(echo "$sp" | jq -r '.displayName')" --vault-name "$keyvaultName" --value "$(echo "$sp" | jq -r '.password')")
      else
        echo -e "${RED}ERROR: Failed to assign 'Key Vault Secrets Officer' role to Key Vault '$keyvaultName'. Please investigate or create manually. Skip.${NC}"
      fi
    fi
  fi
}

#------------------------------------------------#
# MAIN SCRIPT EXECUTION
#------------------------------------------------#
echo -e "${YELLOW}#======================================================================#"
echo -e "${GREEN}                         Azure Bootstrap Script"
echo -e "${YELLOW}#======================================================================#"

# Main: Run functions.
echo -e "${GREEN}- Setting up script configuration...${NC}"
convert_tags
echo -e "${GREEN}- Obtaining tenant details...${NC}"
get_tenant_root_mg
echo -e "${GREEN}- Renaming default subscription...${NC}"
rename_default_sub
echo -e "${GREEN}- Creating Entra ID group...${NC}"
create_entra_group
echo -e "${GREEN}- Configuring Service Principal...${NC}"
create_service_principal
echo -e "${GREEN}- Deploying resources for Terraform backend...${NC}"
deploy_terraform_backend
echo -e "${GREEN} *** COMPLETE! *** ${NC}"

# Results/Output.
echo
echo -e "${GREEN}| SERVICE PRINCIPAL ---------------------------------------------------|${NC}"
echo -e "${YELLOW}[Entra] Contributor Group:${NC} $entraGroupName"
echo -e "${YELLOW}[Service Principal] Name:${NC} $(echo "$sp" | jq -r '.displayName')"
echo -e "${YELLOW}[Service Principal] Tenant:${NC} $(echo "$sp" | jq -r '.tenant')"
echo -e "${YELLOW}[Service Principal] AppId:${NC} $(echo "$sp" | jq -r '.appId')"
echo -e "${YELLOW}[Service Principal] Secret:${NC} $(echo "$sp" | jq -r '.password')"
echo
echo -e "${GREEN}| RESOURCES -----------------------------------------------------------|${NC}"
echo -e "${YELLOW}[Default Subscription] ID:${NC} $default_sub_id"
echo -e "${YELLOW}[Default Subscription] Name:${NC} $defaultSubNameNew"
echo -e "${YELLOW}[Terraform] Resource Group:${NC} $(echo $resource_group | jq -r '.name')"
echo -e "${YELLOW}[Terraform] Storage Account:${NC} $(echo $storage_account | jq -r '.name')"
echo -e "${YELLOW}[Terraform] Container:${NC} $(echo $container | jq -r '.name')"
echo
echo -e "${YELLOW}#======================================================================#"
# clear && ./scripts/bootstrap/bootstrap-azure.sh
