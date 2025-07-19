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
$servicePrincipalName = "$orgPrefix-$platform-$service-$environment-sp" # Service Principal name

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
        Write-Log -Level "WRN" -Stage $stage -Message "AzureCLI is not installed. Please run the 'local-setup' script and try again."
    } 
    else {
        Write-Log -Level "INF" -Stage $stage -Message "AzureCLI is already installed."
    }
}

function Deploy-AzureBootstrap {

    Write-Log -Level "INF" -Stage "Deploy" -Message "Starting resource deployment..."
    New-AzResourceGroup -Name $resourceGroupName -Location $location -Tags $tags
    New-AzStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroupName -Tags $tags
    New-AzBlobContainer -Name $containerName -StorageAccountName $storageAccountName
    New-AzServicePrincipal -Name $servicePrincipalName -ResourceGroupName $resourceGroupName
    New-AzRoleAssignment -ServicePrincipalName $servicePrincipalName -RoleDefinitionName "Contributor" -Scope "/subscriptions/$($Global:subscriptionId)/resourceGroups/$resourceGroupName"
    Write-Log -Level "INF" -Stage "Deploy" -Message "Resources deployed successfully."

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

# Deploy Resources.


# End
Write-Log -Level "INF" -Stage "END" -Message "Utility script execution completed."
Write-Host "`r`n=============== Bootstrap Script: Complete ===============`r`n"

# EOF