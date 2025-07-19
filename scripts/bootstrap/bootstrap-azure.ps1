#=====================================================#
# Bootstrap: Azure Tenant (Windows PowerShell)
#=====================================================#

# DESCRIPTION:
# Azure Tenant Bootstrap Script for Terraform Backend.
# Sets up a Terraform backend in Azure using Storage Account and Blob Container.
# It also creates a Service Principal for Azure DevOps/Terraform integration.

# NOTE: 
# Requires administrator privileges to run.

# USAGE:
# .\scripts\bootstrap\bootstrap-azure.ps1

#------------------------------------------------#
# VARIABLES
#------------------------------------------------#

$orgPrefix = "tjs" # Short code name for the organization.
$location = "australiaeast"
$environment = "prd" # prd, dev, tst
$owner = "CloudOps" # CloudOps, SecOps, ITOps
$platform = "sys" # sys, app, web, inf, sec
$project = "alzplatform" # alz-platform, alz-app, alz-web
$service = "terraform" # terraform, ansible, kubernetes, security
$creator = "Initial-Setup" # Initial-Setup, UserName
$tags = @{ 
    environment = $environment;
    owner = $owner;
    platform = $platform; 
    project = $project;
    service = $service; 
    created = (Get-Date -f 'yyyyMMddHHmmss');
    creator = $creator; 
}
[string]$tagString = ($tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ' '
$nameLong = "$orgPrefix-$platform-$project-$environment" # Long name for descriptive purposes
$nameShort = "$orgPrefix$($platform)$($service)$($environment)" # Short name for resource naming
$resourceGroupName = "$nameLong-rg" # Resource Group name
$storageAccountName = "$nameShort$(Get-Random -Minimum 100000 -Maximum 999999)" # Random suffix, max 24 characters
$containerName = "$orgPrefix-$platform-$service-tfstate" # Blob Container name
$adoOrgUrl = "https://dev.azure.com/tim-shand/" # Azure DevOps Organization URL
$adoProjectName = "Home Lab - Azure Landing Zone" # Azure DevOps Project name
$serviceConnectionName = "$orgPrefix-$platform-$service-$environment-sc" # Service Connection name
$servicePrincipalName = "$orgPrefix-$platform-$service-$environment-sp" # Service Principal name



#==========================================================================#
# FUNCTIONS
#==========================================================================#

# Function: Check for, and install required applications. ----------------------------#
function Get-RequiredApps($requiredApps) {
    Write-Host " - Checking for required applications..."
    ForEach($app in $requiredApps) {
        if (-not (Get-Command $app.Cmd -ErrorAction SilentlyContinue)) {
            Write-Host "- $($app.Name) is not installed. Installing..."
            Invoke-Command -ScriptBlock {winget install --exact --id $($app.WinGetName) --accept-source-agreements --accept-package-agreements --disable-interactivity}
            if (-not (Get-Command $app.Cmd -ErrorAction SilentlyContinue)) {
                Write-Host "ERROR: $($app.Name) installation failed. Please install it manually." -ForegroundColor Yellow
                exit 1
            } else {
                Write-Host "INFO: $($app.Name) installed successfully." -ForegroundColor Green
            }
        } 
        else {
            Write-Host "INFO: $($app.Name) is already installed." -ForegroundColor Green
        }
    }
}

# Function: Check for and install reuqired Powershell modules. ----------------------#
function Get-RequiredModules($requiredPSModules){
    Write-Host " - Checking for required PowerShell modules..."
    ForEach($m in $requiredPSModules){
        if(!(Get-InstalledModule -Name $m -ErrorAction SilentlyContinue)){
            Write-Host "- Module '$m' is not installed. Installing..."
            Try{
                Install-Module -Name $m -Repository PSGallery -Force -AllowClobber
                Write-Host "INFO: Module '$m' installed successfully." -ForegroundColor Green
            }
            Catch{
                $err = $_.ExceptionMessage
                Write-Host "ERROR: Module '$m' installation failed. Please install it manually.`r`n$err" -ForegroundColor Yellow
            }
        } 
        else{
            Write-Host "INFO: Module '$m' is already installed." -ForegroundColor Green
        }
    }
}

# Function: Configure Azure DevOps  -------------------------------------------------#
function Set-AzureDevOps {
    param (
        [string]$adoOrgUrl,
        [string]$adoProjectName,
        [string]$serviceConnectionName, 
        [string]$tenantId, 
        [string]$subscriptionId, 
        [string]$subscriptionName, 
        [string]$mgId
    )

    # Ensure Azure DevOps CLI extension is installed.
    if (-not (az extension list --query "[?name=='azure-devops'].name" -o tsv)) {
        Write-Host " - Installing Azure DevOps CLI extension..."
        az extension add --name azure-devops --only-show-errors
        if (az extension list --query "[?name=='azure-devops'].name" -o tsv) {
            Write-Host "INFO: Azure DevOps CLI extension installed successfully." -ForegroundColor Green
        } else {
            Write-Host "ERROR: Azure DevOps CLI extension installation failed. Please install it manually." -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "INFO: Azure DevOps CLI extension is already installed." -ForegroundColor Green
    }

    # Set defaults for Azure DevOps CLI.
    az devops configure --defaults organization=$adoOrgUrl project=$adoProjectName

    #Write-Host " - Creating Service Connection with Workload Identity Federation..."
    ### Not currently supported by Azure DevOps CLI.

    <# Not currently supported by Azure DevOps CLI.
    az devops service-endpoint azurerm create `
        --name $serviceConnectionName `
        --azure-rm-service-principal-id autoCreateServicePrincipal `
        --azure-rm-tenant-id $tenantId `
        --azure-rm-subscription-id $subscriptionId `
        --azure-rm-subscription-name "$subscriptionName" `
        --use-workload-identity-auth true `
        --scope "/providers/Microsoft.Management/managementGroups/$mgId" `
        --enable-for-all true `
        --organization $adoOrgUrl `
        --project $adoProjectName
    #>
}

# Function: Create Serivce Principal for Azure DevOps/Terraform -----------------#
function New-ServicePrincipal {
    param (
        [string]$spName,
        [string]$rootMgId
    )
    Write-Host " - Creating Service Principal for Azure DevOps/Terraform..."
    $sp = (az ad app create --display-name "$spName" --query appId -o tsv)
    $clientSecret = $(az ad app credential reset --id "$sp" --display-name "client_secret_$(Get-Date -f 'yyyyMMddHHmmss')" --append --years 1 --query password -o tsv)
    $spId = (az ad sp create --id "$sp" --query id -o tsv)
    az role assignment create --assignee "$spId" --role "Contributor" --scope "/providers/Microsoft.Management/managementGroups/$rootMgId"
    return @{
        AppId = $sp
        ClientSecret = $clientSecret
        ServicePrincipalId = $spId
    }
}

# Function: Configure Terraform Remote Backend in Azure Storage Account -------------#
function Set-TerraformBackend {
    param (
        [string]$resourceGroupName,
        [string]$storageAccountName,
        [string]$containerName,
        [string]$location,
        [hashtable]$tagString
    )

    Write-Host " - Creating Resource Group..."
    az group create --name $resourceGroupName --location $location --tags $tagString

    Write-Host " - Creating Storage Account for Terraform backend..."
    az storage account create `
    --name $storageAccountName `
    --resource-group $resourceGroupName `
    --location $location `
    --sku Standard_LRS `
    --encryption-services blob `
    --kind StorageV2 `
    --allow-blob-public-access false `
    --min-tls-version TLS1_2 `
    --tags $tagString

    Write-Host " - Creating Blob Container..."
    az storage container create `
    --name $containerName `
    --account-name $storageAccountName `
    --public-access off `
    --auth-mode login
}

function Get-DeploymentResults () {
    # Output the configuration details.
    Write-Host "`nConfiguration Summary:"
    Write-Host " - Resource Group: $resourceGroupName"
    Write-Host " - Storage Account: $storageAccountName"
    Write-Host " - Blob Container: $containerName"
    Write-Host " - Azure DevOps Project: $adoProjectName"
    Write-Host " - Service Principal App Id: $($servicePrincipal.AppId)"
    Write-Host " - Service Principal Secret: $($servicePrincipal.ClientSecret)"
    Write-Host "`r`nRun 'terraform init' in your Terraform project to configure the backend.`r`n"
}

#===========================================================================#
### MAIN ###
#===========================================================================#

# Check for administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "WARN: You must run this script as Administrator."
    exit 1
}

# App and module checks.
Get-RequiredApps($requiredApps)
#Get-RequiredModules($requiredPSModules)

# Connect to Azure.
if (-not (az account show)) {
    Write-Host " - Logging into Azure..."
    az login --use-device-code
}
Write-Host " - Getting Azure details..."
$tenantId = az account show --query tenantId -o tsv
$subscriptionId = az account show --query id -o tsv
$subscriptionName = az account show --query name -o tsv
$rootMgId = az account management-group list --query "[?displayName=='Tenant Root Group'].name" -o tsv

# Create Service Principal for Azure DevOps/Terraform.
$servicePrincipal = New-ServicePrincipal -spName $servicePrincipalName -rootMgId $rootMgId

# Configure Azure DevOps.
Set-AzureDevOps -adoOrgUrl $adoOrgUrl -adoProjectName $adoProjectName `
    -serviceConnectionName $serviceConnectionName `
    -tenantId $tenantId `
    -subscriptionId $subscriptionId `
    -subscriptionName $subscriptionName `
    -mgId $mgId

# Configure Terraform backend.
Set-TerraformBackend -resourceGroupName $resourceGroupName `
    -storageAccountName $storageAccountName `
    -containerName $containerName `
    -location $location `
    -tags $tagString

# Get deplyment results.
Get-DeploymentResults

# End