#!/bin/bash

#=====================================================#
# Bootstrap: Azure Preparation for Terraform
#=====================================================#

# DESCRIPTION:
# Bootstrap script for using Terraform with Azure.
# Prepares local system with required packages and applications.
# Creates a new Entra group with 'Contributor' role assignment at tenant root management group.
# Creates a Service Principal to be used by Terraform, adds as member to above group.
# Configures a Terraform remote backend in Azure using Storage Account and Blob Container.

# NOTE: 
# Requires administrator privileges to run.

# USAGE:
# sudo ./scripts/bootstrap/bootstrap-azure.sh

#------------------------------------------------#
# VARIABLES
#------------------------------------------------#
# Console Colour Config
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color / Reset

# Define list of required applications to be installed.
requiredApps="jq git terraform gh curl"
tf_minversion="1.5.0" # Minimum Terraform version.
tf_file_output_dir="./environments/azure/platform" # Directory for created Terraform files.

# Organization and Project Variables
location="australiaeast"
location_full="Australia East"
orgPrefix="tjs" # Short code name for the organization.
project="platform" # platform, landingzone
service="terraform" # terraform, ansible, kubernetes, security
service_short="tf" # tf, kube, ans, sec
environment="prd" # prd, dev, tst
tag_creator="Bootstrap"
tag_owner="CloudOps"

# Azure: Service Principal and Entra Groups
rootMGName="Tenant Root Group" # Default Management Group name for the root management group.
servicePrincipalName="$orgPrefix-$project-$service-sp" # Service Principal name
entraGroupName="Sec-RBAC-Global-Contributors-IAC"
entraGroupDesc="Security group for privileged identities to assign contributor (RBAC) role at tenant level."

# Azure: Resource Group, Storage Account, and Blob Container
subNameNew="$orgPrefix-$project-sub"
resourceGroupName="$orgPrefix-$project-$service-$environment-rg" # Resource Group name
storageAccountName="${orgPrefix}${project}${service_short}${environment}$(shuf -i 10000000-99999999 -n 1)" # Random suffix, max 24 characters
containerName="$orgPrefix-$project-$service-tfstate" # Blob Container name
containerKeyName="$orgPrefix-$project-$service.tfstate" # Container Key name

# Tag String Compilation used for resources.
tag_string="project=$project creator=$tag_creator service=$service environment=$environment created="$(date +"%Y%m%d%H%M%S")" owner=$tag_owner"

#------------------------------------------------#
# FUNCTIONS
#------------------------------------------------#

# Function: Install required apps/packages on local machine.
install_required_apps() {
    for app in $requiredApps; do
        if ! command -v $app &> /dev/null; then
            echo -e "${YELLOW}WARN: $app is not installed. Installing..."
            sudo apt-get install -y $app &> /dev/null
            if ! command -v $app &> /dev/null; then
                echo -e "${RED}ERROR: Failed to install $app. Please install manually.${NC}"
                exit 1
            else
                echo -e "${GREEN}INFO: $app installed successfully.${NC}"
            fi
        else
            echo -e "${GREEN}INFO: $app is already installed.${NC}"
        fi
    done
    # Install Azure CLI (script adds to sources list and installs).
    if ! command -v az &> /dev/null; then
        echo -e "${YELLOW}WARN: Azure CLI is not installed. Installing...${NC}"
        curl -sL https://aka.ms/InstallAzureCLIDeb | bash &> /dev/null
        if ! command -v az &> /dev/null; then
            echo -e "${RED}ERROR: Failed to install Azure CLI. Please install manually.${NC}"
        else
            echo -e "${GREEN}INFO: Azure CLI installed successfully.${NC}"
        fi
    else
        echo -e "${GREEN}INFO: Azure CLI is already installed. Upgrading...${NC}"
        az upgrade
    fi
}

# Function: Rename default subscription for use as Platform landing zone.
rename_default_sub(){
    default_sub_id=$(az account list --query "[?isDefault].id" -o tsv)
    rename_sub=$(az account subscription rename --id "$default_sub_id" --name "$subNameNew" --only-show-errors)
    if [[ -z $rename_sub ]]; then
        echo -e "${RED}ERROR: Failed to rename default subscription. Skip.${NC}"
    fi
}

# Function: Get tenant root management group ID for role assignment.
get_tenant_root_mg(){
    root_mg_id=$(az account management-group list --query "[?displayName=='$rootMGName'].id" -o tsv)
    if [[ -z "$root_mg_id" ]]; then
        echo -e "${RED}ERROR: Tenant Root Group not found (required). Unable to proceed. Abort.${NC}"
        exit 1
    fi
}

# Function: Create Serivce Principal for Terraform deployments.
create_service_principal(){
    sp=$(az ad sp create-for-rbac --name "$servicePrincipalName" --only-show-errors)
    if [[ -z "$sp" ]]; then
        echo -e "${RED}ERROR: Failed to configure Service Principal required. Unable to proceed. Abort ${NC}"
        exit 1
    fi
    sp_id=$(az ad sp show --id "$(echo "$sp" | jq -r '.appId')" --query "id" -o tsv)
}

# Function: Create Entra ID group for RBAC assignment of role 'Contributor' at tenant root. 
configure_entra_group(){
    # Create Entra group and assign role.
    entra_group=$(az ad group create --display-name "$entraGroupName" --mail-nickname "$entraGroupName" \
        --description "$entraGroupDesc" --only-show-errors)
    if [[ -z "$entra_group" ]]; then
        echo -e "${RED}ERROR: Failed to configure Entra group (required) '$entraGroupName'. Abort.${NC}"
        exit 1
    fi
    sleep 10 # Sleep to avoid delay replication issues.
    # Add Service Principal as group member.
    sp_group_member=$(az ad group member add --group "$(echo $entra_group | jq -r '.id')" --member-id "$sp_id" --only-show-errors)
    sleep 5 # Sleep to avoid delay replication issues.
    sp_group_check=$(az ad group member check --group "$(echo $entra_group | jq -r '.id')" --member-id "$sp_id" --only-show-errors)
    if [[ -z $sp_group_check ]]; then
        echo -e "${RED}ERROR: Failed to add Service Principal '($(echo "$sp_id"))' to Entra group (required) '$entraGroupName'. Abort.${NC}"
        exit 1
    elif [[ "$(echo $sp_group_check | jq -r '.value')" == 'false' ]]; then
        echo -e "${RED}ERROR: Failed to add Service Principal '($(echo "$sp_id"))' to Entra group (required) '$entraGroupName'. Abort.${NC}"
        exit 1
    fi
    # Assign Contributor role to group at tenant root scope.
    sleep 10 # Sleep to avoid delay replication issues.
    group_role_assignment=$(az role assignment create --assignee-object-id "$(echo "$entra_group" | jq -r '.id')" \
        --role Contributor --scope "$root_mg_id" --assignee-principal-type "Group" --only-show-errors)
    if [[ -z "$group_role_assignment" ]]; then
        echo -e "${RED}ERROR: Failed to assign role 'Contributor' (required) for Entra group '$entraGroupName'. Abort.${NC}"
        exit 1
    fi
}

# Function: Deploy resources for Terraform backend.
deploy_terraform_backend(){
    # Create Resource Group.
    resource_group=$(az group create --name "$resourceGroupName" --location "$location" --tags "$tag_string")
    if [[ -z "$resource_group" ]]; then
        echo -e "${RED}ERROR: Failed to create Resource Group (required) '$resourceGroupName'. Abort.${NC}"
        exit 1
    fi
    # Create Storage Account.
    storage_account=$(az storage account create --name "$storageAccountName" --resource-group "$resourceGroupName" \
        --access-tier Hot --tags "$tag_string" --sku Standard_LRS --only-show-errors)
    if [[ -z "$storage_account" ]]; then
        echo -e "${RED}ERROR: Failed to create Storage Account (required) '$storageAccountName'. Abort.${NC}"
        exit 1
    fi
    # Create Container (produces true/false).
    container_created=$(az storage container create --name "$containerName" --account-name "$(echo $storage_account | jq -r '.name')" --auth-mode login)
    if [[ -z "$container_created" ]]; then
        echo -e "${RED}ERROR: Failed to create Storage Container (required) '$containerName'. Abort.${NC}"
        exit 1
    else
        container_exists=$(az storage container exists --name "$containerName" --account-name "$(echo $storage_account | jq -r '.name')" --auth-mode login)
        if [[ -z $container_exists ]]; then
            echo -e "${RED}ERROR: Failed to check for Storage Container (required) '$containerName'. Abort.${NC}"
            exit 1
        else
            if [[ "$(echo $container_exists | jq -r '.exists')" == 'false' ]]; then
                echo -e "${RED}ERROR: Failed to create Storage Container (required) '$containerName'. Abort.${NC}"
                exit 1
            fi
        fi
    fi
}

populate_tf_files(){
# Populate Terraform files.
cat > "$(echo $tf_file_output_dir)/providers.tf" <<TFPROVIDERS
# Populated by Bootstrap Script.
terraform {
    required_version = ">= $tf_minversion"
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~> 4.37"
        }
        azapi = {
            source  = "Azure/azapi"
            version = "~> 2.5.0"
        }
        random = {
            source  = "hashicorp/random"
            version = "~> 3.5"
        }
        time = {
            source  = "hashicorp/time"
            version = "~> 0.9"
        }
    }
    backend "azurerm" {
        resource_group_name   = var.tf_backend_resourcegroup
        storage_account_name  = var.tf_backend_storageaccount
        container_name        = var.tf_backend_container
        key                   = var.tf_backend_key
    }
}

provider "azapi" {
    tenant_id         = var.tf_tenant_id
    subscription_id   = var.tf_subscription_id
    client_id         = var.tf_client_id
    client_secret     = var.tf_client_secret
}

provider "azurerm" {
    tenant_id         = var.tf_tenant_id
    subscription_id   = var.tf_subscription_id
    client_id         = var.tf_client_id
    client_secret     = var.tf_client_secret
}
TFPROVIDERS

# Terraform Variables file.
cat > "$(echo $tf_file_output_dir)/variables.tf" <<TFVARIABLES
# Populated by Bootstrap Script.
variable "tf_backend_resourcegroup" {
    type = string
    description = "Terraform backend Resource Group name."
}
variable "tf_backend_storageaccount" {
    type = string
    description = "Terraform backend Storage Account name."
}
variable "tf_backend_container" {
    type = string
    description = "Terraform backend Resource Group name."
}
variable "tf_backend_key" {
    type = string
    description = "Terraform backend Key name."
}

# Azure: Platform Variables
variable "tf_tenant_id" {
    type = string
    description = "Azure Tenant."
}
variable "tf_subscription_id" {
    type = string
    description = "Azure Subscription."
}
variable "tf_client_id" {
    type = string
    description = "Azure Service Principal (AppId)."
}
variable "tf_client_secret" {
    type = string
    description = "Azure Service Principal Client Secret."
}
variable "default_location" {
    type = string
    description = "Default Azure location for resources."
}

# Naming Conventions (using validations)
variable "org_prefix" {
    type = string
    description = "Core naming prefix for majority of resources."
    validation {
        condition     = length(var.org_prefix) == 3 # Must be exactly 3 characters
        error_message = "The org_pefix must be exactly 3 characters long."
    }
}
variable "org_service" {
    type = string
    description = "Service code for naming convention."
}
variable "org_project" {
    type = string
    description = "Project code for naming convention."
}
variable "org_environment" {
    type = string
    description = "Environment code for naming convention (prd, dev, tst)."
    validation {
        condition = contains(["prd","dev","tst" ], var.org_environment)
        error_message = "Valid value is one of the following: prd, dev, tst."
    }
}
variable "tag_creator" {
    type = string
    description = "Name of account creating resources."
}
variable "tag_owner" {
    type = string
    description = "Name of account creating resources."
}
TFVARIABLES

# Terraform TFVARS file.
cat > "$(echo $tf_file_output_dir)/terraform.tfvars" <<TFVARS
# Populated by Bootstrap Script.
tf_backend_resourcegroup = "$(echo $resource_group | jq -r '.name')"
tf_backend_storageaccount = "$(echo $storage_account | jq -r '.name')"
tf_backend_container = "$(echo $containerName)"
tf_backend_key = "$(echo $containerKeyName)"

# Azure: Platform Variables
tf_tenant_id = "$(echo "$sp" | jq -r '.tenant')"
tf_subscription_id = "$default_sub_id"
tf_client_id = "$(echo "$sp" | jq -r '.appId')"
tf_client_secret = "$(echo "$sp" | jq -r '.password')"

# Naming Conventions (using validations)
default_location = "$location_full"
org_prefix = "$orgPrefix" # Short code name for the organization
org_project = "$project" # platform, landingzone
org_service = "$service" # Terraform, Application, Ansible
org_environment = "$environment"

# Tag Values
tag_creator = "$tag_creator" # Creator of resources
tag_owner = "$tag_owner" # Owner of the resources
TFVARS
}

#------------------------------------------------#
# MAIN SCRIPT EXECUTION
#------------------------------------------------#

echo -e "${YELLOW}#======================================================================#"
echo -e "${GREEN}                    Azure Terraform Bootstrap Script"
echo -e "${YELLOW}#======================================================================#"

# Check if the script is run with root privileges.
if [ "$EUID" -ne 0 ]; then
  echo "WARNING: Script requires to be run with root privileges (sudo). Exiting..."
  exit 1
fi

# Install required applications/packages.
install_required_apps

# Login to Azure.
if [[ -z $(az account show) ]]; then
    echo -e "${YELLOW}- Azure: No current session found. Please login.${NC}"
    az_session=$(az login)
else
    echo -e "${GREEN}- Azure: Existing active session found. Proceed.${NC}"
    az_session=$(az account show)
fi

# Install/configure Azure CLI extensions.
az config set extension.dynamic_install_allow_preview=true
az extension add --upgrade -n account

# Get tenant root management group.
echo -e "${GREEN}- Obtaining tenant details...${NC}"
get_tenant_root_mg
# Rename default subscription.
echo -e "${GREEN}- Renaming default subscription...${NC}"
rename_default_sub
# Create Service Principal.
echo -e "${GREEN}- Creating Service Principal for Terraform...${NC}"
create_service_principal
# Configure Entra group and role assignment.
echo -e "${GREEN}- Configuring Entra group and assigning roles...${NC}"
configure_entra_group
# Deploy resources used for remote Terraform backend.
echo -e "${GREEN}- Deploying resources for Terraform backend...${NC}"
deploy_terraform_backend
# Create Terrform files using bootstrap variables.
echo -e "${GREEN}- Populating Terraform files...${NC}"
populate_tf_files

# Complete.
echo -e "${GREEN}- COMPLETE!${NC}"

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
echo -e "${YELLOW}[Default Subscription] Name:${NC} $subNameNew"
echo -e "${YELLOW}[Terraform] Resource Group:${NC} $(echo $resource_group | jq -r '.name')"
echo -e "${YELLOW}[Terraform] Storage Account:${NC} $(echo $storage_account | jq -r '.name')"
echo -e "${YELLOW}[Terraform] Container:${NC} $(echo $containerName)"
echo
echo -e "${YELLOW}#======================================================================#"
# clear && sudo ./scripts/bootstrap/bootstrap-azure-tf.sh
