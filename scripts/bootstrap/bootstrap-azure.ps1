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
# .\scripts\bootstrap\bootstrap-azure-windows.ps1

#------------------------------------------------#
# VARIABLES
#------------------------------------------------#

# Global Variables
[string]$Global:scriptName = "LocalSystemSetup" # Used for log file naming.
[string]$Global:LoggingLocal = $true # Enable local log file logging.
[string]$Global:LoggingLocalDir = "$env:USERPROFILE" # Local log file log path.
[string]$Global:LoggingEventlog = $true # Enable Windows Eventlog logging.
[int]$Global:LoggingEventlogId = 900 # Windows Eventlog ID used for logging.

# Object for all results.
$global:totalResults = @{}
$orgPrefix = "tjs" # Short code name for the organization.
$location = "australiaeast"
$environment = "prd" # prd, dev, tst
$platform = "mgt" # sys, app, web, inf, sec
$project = "platform" # platform, app, web
$service = "terraform" # terraform, ansible, kubernetes, security
$subNameNew = "$orgPrefix-$platform-$project-sub" # New subscription name.
$tags = @{ 
    environment = $environment;
    owner = "$($platform)-bootstrap";
    platform = $platform;
    project = $project;
    service = $service;
    created = (Get-Date -f 'yyyyMMddHHmmss');
    creator = "$($platform)-bootstrap";
}
$rootMGName = "Tenant Root Group" # Management Group name for the root management group.
$resourceGroupName = "$orgPrefix-$platform-$service-rg" # Resource Group name
$storageAccountName = "$orgPrefix$($platform)$($service)$(Get-Random -Minimum 10000000 -Maximum 99999999)" # Random suffix, max 24 characters
$containerName = "$orgPrefix-$platform-$service-tfstate" # Blob Container name
$servicePrincipalName = "$orgPrefix-$platform-$service-sp" # Service Principal name

#==========================================================================#
# FUNCTIONS
#==========================================================================#

# Function: Check for script run with admin priviliages.
function Get-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        Write-Log -Level "ERR" -Stage "Script" -Message "WARNING: You must run this script as Administrator."
        exit 1
    }
}

# Function: Custom logging to local file or Event Log.
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("INF", "WRN", "ERR")]
        [string]$Level,

        [Parameter(Mandatory=$true)]
        [string]$Stage,

        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    # Check if local logging is enabled.
    if($Global:LoggingLocal){
        if(!(Test-Path -Path "$Global:LoggingLocalDir$("\")$Global:scriptName$("_")$(Get-Date -f 'yyyyMMdd').log")){
            New-Item -ItemType File -Path "$Global:LoggingLocalDir$("\")$Global:scriptName$("_")$(Get-Date -f 'yyyyMMdd').log" -Force
        }
        Write-Output "$timestamp [$Level] | $Stage | $Message" | `
        Out-File -FilePath "$Global:LoggingLocalDir$("\")$Global:scriptName$("_")$(Get-Date -f 'yyyyMMdd').log" -Append
    }

    # Check if Event Log logging is enabled.
    if($Global:LoggingEventlog){
        switch ($Level){
            "INF" {$EntryType = "Information"; $textColour = "Green"}
            "WRN" {$EntryType = "Warning"; $textColour = "Yellow"}
            "ERR" {$EntryType = "Error"; $textColour = "Red"}
            default {$EntryType = "Information"; $textColour = "White"}
        }
        New-EventLog -LogName Application -Source $Global:scriptName -ErrorAction SilentlyContinue
        Write-EventLog -LogName Application -Source $Global:scriptName -EntryType $EntryType -EventID $Global:LoggingEventlogId -Message ("[$Stage] $message")
    }
    
    # Write to console.
    Write-Host "$timestamp [$Level] | $Stage | $Message" -ForegroundColor $textColour
}

# Function: Check for, and install required applications.
function Get-AzureCLI {
    $stage = "Check-AzureCLI"
    if (-not (Get-Command "az" -ErrorAction SilentlyContinue)) {
        Write-Log -Level "WRN" -Stage $stage -Message "Azure CLI is not installed. Please run the 'local-setup' script and try again."
    } 
    else {
        Write-Log -Level "INF" -Stage $stage -Message "Azure CLI is already installed."
    }
}

# Function: Check login to Azure.
function Get-AzureLogin {
    $global:azSession = (Get-AzContext -ErrorAction Stop)
    if ($global:azSession) {
        Write-Log -Level "INF" -Stage "Get-AzureLogin" -Message "Logged in to Azure as $($global:azSession.Account.Id)."
        #return $currentSession
    } else{
        $azConnection = Connect-AzAccount -ErrorAction Stop        
        if ($azConnection) {
            do {
                $userResponse = (Read-Host -Prompt "Proceed as '$($currentSession.Account)' in tenant '$($currentSession.TenantDomain)' [Y/N]")
                if ($userResponse -inotmatch "^(Y|N|y|n)$") {
                    Write-Log -Level "ERR" -Stage "Get-AzureLogin" -Message "Invalid response. Please enter 'Y' or 'N'."
                } else{
                    if ($userResponse -match "^(N|n)$") {
                        Write-Log -Level "ERR" -Stage "Get-AzureLogin" -Message "User cancelled Azure login. Abort."
                        exit 1
                    } else{
                        $global:azSession = (Get-AzContext -ErrorAction Stop)                        
                        Write-Log -Level "INF" -Stage "Get-AzureLogin" -Message "Successfully logged in to Azure."
                    }
                }
                } while (
                # Repeat until a valid response is given.
                $userResponse -notmatch "^(Y|N|y|n)$"
            )
        } else {
            Write-Log -Level "ERR" -Stage "Get-AzureLogin" -Message "Failed to log in to Azure. Please run 'Connect-AzAccount' and try again."
            exit 1
        }        
    }
}

# Function: Rename default subscription.
function Rename-DefaultSubscription {
    $stage = "Rename-DefaultSubscription"
    $defaultSub = Get-AzSubscription -SubscriptionId $($global:azSession.Subscription.Id) -ErrorAction SilentlyContinue
    if ($defaultSub) {
        $renameSub = (Rename-AzSubscription -Id $defaultSub.Id -SubscriptionName $subNameNew -ErrorAction SilentlyContinue)
        if ($renameSub) {
            Write-Log -Level "INF" -Stage $stage -Message "Default subscription renamed to '$($subNameNew)'."
            $global:totalResults += @{
                SubscriptionName = $subNameNew
                SubscriptionId = $global:azSession.Subscription.Id
            }
        } else {
            Write-Log -Level "ERR" -Stage $stage -Message "Failed to rename default subscription. Please try again."
            exit 1
        }
    } else {
        Write-Log -Level "WRN" -Stage $stage -Message "Default subscription not found. Skipping rename."
    }
}

# Function: Check for, and install required resources.
function Add-AzureResources {
    $stage = "Deploy-AzureBootstrap"
    Write-Log -Level "INF" -Stage "Deploy" -Message "Starting Azure resource deployment..."

    # Resource Group: Check if the resource group already exists, create if not present.
    $rg = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if ($rg) {
        Write-Log -Level "WRN" -Stage $stage -Message "Resource group '$resourceGroupName' already exists. Skip."
    } else {
        $rg = New-AzResourceGroup -Name $resourceGroupName -Location $location -Tags $tags -ErrorAction Stop
        Write-Log -Level "INF" -Stage $stage -Message "Created resource group '$resourceGroupName'."
    }

    # Storage Account: Check if the storage account already exists, create if not present.
    $storageAccount = Get-AzStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
    if ($storageAccount) {
        Write-Log -Level "WRN" -Stage $stage -Message "Storage account '$storageAccountName' already exists. Skip."
    } else {
        Write-Log -Level "INF" -Stage $stage -Message "Creating storage account '$storageAccountName'."
        $storageAccount = New-AzStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroupName `
            -Location $location -SkuName "Standard_LRS" -Tags $tags -ErrorAction Stop
    }

    # Blob Container: Check if the blob container already exists, create if not present.
    $storageContext = (New-AzStorageContext -StorageAccountName $storageAccountName)
    $saContainer = Get-AzStorageContainer -Name $containerName -Context $storageContext -ErrorAction SilentlyContinue
    if ($saContainer) {
        Write-Log -Level "WRN" -Stage $stage -Message "Blob container '$containerName' already exists. Skip."
    } else {
        Write-Log -Level "INF" -Stage $stage -Message "Creating blob container '$containerName'."
        $saContainer = New-AzStorageContainer -Name $containerName -Context $storageContext -ErrorAction Stop
    }

    # Append to global results.
    $global:totalResults += @{
        Location = $location
        ResourceGroupName = $resourceGroupName
        StorageAccountName = $storageAccountName
        ContainerName = $containerName
    }
}

# Function: Deploy Azure Service Principal.
function Add-AzureServicePrincipal {
    $stage = "Deploy-AzureServicePrincipal"
    # Service Principal: Check if the service principal already exists, create if not present.
    $sp = Get-AzADServicePrincipal -DisplayName $servicePrincipalName -ErrorAction SilentlyContinue
    if ($sp) {
        Write-Log -Level "WRN" -Stage $stage -Message "Service principal '$servicePrincipalName' already exists. Regenerating credential..."
        $newSpCred = (New-AzADAppCredential -ApplicationId $sp.AppId -EndDate (Get-Date).AddYears(1) -ErrorAction Stop)
        if ($newSpCred) {
            Write-Log -Level "INF" -Stage $stage -Message "Service principal '$servicePrincipalName' credential regenerated successfully."
            # Append to global results.
            $global:totalResults += @{
                ServicePrincipalName = $sp.DisplayName
                TenantId = $sp.AppOwnerOrganizationId
                ServicePrincipalAppId = $sp.AppId
                ServicePrincipalSecret = $newSpCred.SecretText
            }
        } else {
            Write-Log -Level "ERR" -Stage $stage -Message "Failed to regenerate service principal '$servicePrincipalName' credential."
            exit 1
        }
    } else {
        Write-Log -Level "INF" -Stage $stage -Message "Creating service principal '$servicePrincipalName'."
        $sp = New-AzADServicePrincipal -DisplayName $servicePrincipalName -ErrorAction Stop
        if ($sp) {
            Write-Log -Level "INF" -Stage $stage -Message "Service principal '$servicePrincipalName' created successfully."

            # Append to global results.
            $global:totalResults += @{
                ServicePrincipalName = $sp.DisplayName
                ServicePrincipalTenantId = $sp.TenantId
                ServicePrincipalAppId = $sp.AppId
                ServicePrincipalSecret = ($sp.PasswordCredentials).SecretText
            }

            # Assign Role: Assign 'Contributor' role to the service principal on the tenant root management group.
            $rootMG = Get-AzManagementGroup | ?{$_.DisplayName -eq $rootMGName}
            if ($rootMG) {
                $roleAssignment = New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Contributor" -Scope $rootMG.Id -ErrorAction Stop
                if ($roleAssignment) {
                    Write-Log -Level "INF" -Stage $stage -Message "Assigned 'Contributor' role to service principal '$servicePrincipalName' on management group '$($rootMG.DisplayName)'."
                } else {
                    Write-Log -Level "ERR" -Stage $stage -Message "Failed to assign role to service principal '$servicePrincipalName'."
                    exit 1
                }
            } else {
                Write-Log -Level "ERR" -Stage $stage -Message "Management group '$rootMGName' not found."
                exit 1
            }

        } else {
            Write-Log -Level "ERR" -Stage $stage -Message "Failed to create service principal '$servicePrincipalName'."
            exit 1
        }
    }
}

#------------------------------------------------#
# MAIN SCRIPT EXECUTION
#------------------------------------------------#

Write-Host "`r`n=============== Bootstrap Script: Azure Bootstrap Script ===============`r`n"
Write-Host "This script will create resources necessary for deployments via Terraform.`r`n"
Write-Log -Level "INF" -Stage "START" -Message "Azure Bootstrap script execution started."

# Check for administrator privileges.
Get-Admin

# Check for Azure CLI.
Get-AzureCLI

# Login to Azure.
Get-AzureLogin

# Deploy Resources.
Rename-DefaultSubscription
Add-AzureServicePrincipal
Add-AzureResources

# Output all details.
$global:totalResults | format-table

# End
Write-Log -Level "INF" -Stage "END" -Message "Utility script execution completed."
Write-Host "`r`n=============== Bootstrap Script: Complete ===============`r`n"

# EOF