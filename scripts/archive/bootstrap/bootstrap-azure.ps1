#=====================================================#
# Bootstrap: Azure Tenant (Windows PowerShell)
#=====================================================#

<# DESCRIPTION:
Bootstrap script to configure Azure for Terraform deployments.
Creates a new Entra ID group with 'Contributor' role assigned at tenant root management group.
Creates a Service Principal to be used by Terraform, adds as member to above group.
Configures a Terraform remote backend in Azure using Storage Account and Blob Container.

NOTE: Requires administrator privileges to run.

REQUIREMENTS:
- Installed: Azure CLI
- Installed: Terraform
- Powershell Modules: Az, Microsoft.Entra, Az.Subscription

USAGE: .\scripts\bootstrap\bootstrap-azure.ps1

#>

#==========================================================================#
# FUNCTIONS
#==========================================================================#

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
    # Set console text colour.
    switch ($Level){
        "INF" {$EntryType = "Information"; $textColour = "Green"}
        "WRN" {$EntryType = "Warning"; $textColour = "Yellow"}
        "ERR" {$EntryType = "Error"; $textColour = "Red"}
        default {$EntryType = "Information"; $textColour = "White"}
    }    
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    # Check if local logging is enabled.
    if($Global:LoggingLocal){
        if(!(Test-Path -Path "$Global:LoggingLocalDir$("\")$Global:scriptName$("_")$(Get-Date -f 'yyyyMMdd').log")){
            New-Item -ItemType File -Path "$Global:LoggingLocalDir$("\")$Global:scriptName$("_")$(Get-Date -f 'yyyyMMdd').log" -Force
        }
        Write-Output "$timestamp [$Level] | $Stage | $Message" | `
        Out-File -FilePath "$Global:LoggingLocalDir$("\")$Global:scriptName$("_")$(Get-Date -f 'yyyyMMdd').log" -Append
    }    
    # Write to console.
    Write-Host "$timestamp [$Level] | $Stage | $Message" -ForegroundColor $textColour
}

# Function: Check for required applications. Return number of installed apps.
function Get-RequiredApps {
    [string]$stage = "Check-RequiredApps"
    [int]$installedApps = 0
    ForEach($app in $requiredApps){
        if (-not (Get-Command "$($app.Cmd)" -ErrorAction SilentlyContinue)) {
            Write-Log -Level "WRN" -Stage $stage -Message "Application $($app.Name) is not installed. Please install and try again."
        } 
        else {
            Write-Log -Level "INF" -Stage $stage -Message "Application $($app.Name) is installed."
            $installedApps += 1
        }
    }
    return $installedApps
}

# Function: Check/install required Powershell modules. Return number of installed modules.
function Get-RequiredModules {
    [string]$stage = "Check-RequiredModules"
    [int]$installedModules = 0
    ForEach($m in $requiredPSModules){
        if(!(Get-InstalledModule -Name $m -ErrorAction SilentlyContinue)){
            Write-Log -Level "WRN" -Stage $stage -Message "Module '$m' is not installed. Installing..."
            Try{
                Install-Module -Name $m -Repository PSGallery -Force -AllowClobber
                Write-Log -Level "INF" -Stage $stage -Message "Module '$m' installed successfully."
                $installedModules += 1
            }
            Catch{
                $err = $_.ExceptionMessage
                Write-Log -Level "ERR" -Stage $stage -Message "Module '$m' installation failed. Please install and try again.`r`n$err"
            }
        } 
        else{
            Write-Log -Level "INF" -Stage $stage -Message "Module '$m' is already installed."
            $installedModules += 1
        }
    }
    return $installedModules
}

# Function: Check login to Azure.
function Get-AzureLogin {
    do {
        if(!(Get-AzContext -ErrorAction Stop)){
            $azConnection = (Connect-AzAccount)
            if(!($azConnection)){
                Write-Log -Level "ERR" -Stage "Check-AzureLogin" -Message "Failed to authenticate to Azure."
            }
        }
        $azSession = (Get-AzContext | Select * -ErrorAction Stop)
        $userResponse = (Read-Host -Prompt "Proceed as: '$($azSession.Name)' [Y/N]")
        if ($userResponse -inotmatch "^(Y|N|y|n)$") {
            Write-Log -Level "ERR" -Stage "Check-AzureLogin" -Message "Invalid response. Please enter 'Y' or 'N'."
        } else{
            if ($userResponse -match "^(N|n)$") {
                Write-Log -Level "ERR" -Stage "Check-AzureLogin" -Message "User cancelled Azure login."
            } else{
                $azSession = (Get-AzContext -ErrorAction Stop)                        
                Write-Log -Level "INF" -Stage "Check-AzureLogin" -Message "Successfully authenticated to Azure ($($azSession.Account))."
            }
        }
    } while (
        # Repeat until a valid response is given.
        $userResponse -notmatch "^(Y|N|y|n)$"
    )
    return $azSession
}

# Function: Rename default subscription.
function Rename-DefaultSubscription {
    $stage = "Rename-DefaultSubscription"
    $newSubName = "$($orgPrefix)-$($project)-mgt-sub"
    $defaultSub = Get-AzSubscription -SubscriptionId $($global:azSession.Subscription.Id) -ErrorAction SilentlyContinue
    if ($defaultSub) {
        $renameSub = (Rename-AzSubscription -Id $defaultSub.Id -SubscriptionName "$newSubName" -ErrorAction SilentlyContinue)
        if ($renameSub) {
            Write-Log -Level "INF" -Stage $stage -Message "Default subscription renamed to '$newSubName'."
            $global:totalResults += @{
                SubscriptionName = "$newSubName"
                SubscriptionId = $renameSub.SubscriptionId
            }
        } else {
            Write-Log -Level "ERR" -Stage $stage -Message "Failed to rename default subscription. Skip."
        }
    } else {
        Write-Log -Level "WRN" -Stage $stage -Message "Default subscription not found. Skip."
    }
    return $renameSub.SubscriptionId
}

# Function: Created Azure resources for Terraform backend.
function Create-TerraformResources {
    $stage = "Deploy-TerraformResources"

    # Resource Group: Check if the resource group already exists, create if not present.
    $rg = New-AzResourceGroup -Name $tfResourceGroupName -Location $primaryLocation -Tags $tags -ErrorAction Stop -Force
    if(!($rg)){
        Write-Log -Level "ERR" -Stage $stage -Message "Failed to create Resource Group '$($tfResourceGroupName)'."
    } else{
        Write-Log -Level "INF" -Stage $stage -Message "Created Resource Group '$($rg.ResourceGroupName)'."
        
        # Storage Account: Check if the storage account already exists, create if not present.
        $storageAccount = New-AzStorageAccount -Name $tfStorageAccountName -ResourceGroupName "$($rg.ResourceGroupName)" -Location $primaryLocation -SkuName "Standard_LRS" -Tags $tags -ErrorAction Stop
        if(!($storageAccount)){
            Write-Log -Level "ERR" -Stage $stage -Message "Failed to create Storage Account '$($tfStorageAccountName)'."
        } else{
            Write-Log -Level "INF" -Stage $stage -Message "Created Storage Account '$($tfStorageAccountName)'."

            # Blob Container: Create blob container for Terraform state file.
            $storageContext = New-AzStorageContext -StorageAccountName "$($tfStorageAccountName)"
            $saContainer = New-AzStorageContainer -Name $tfContainerName -Context $storageContext -ErrorAction Stop
            if(!($saContainer)){
                Write-Log -Level "ERR" -Stage $stage -Message "Failed to create Storage Container '$($tfContainerName)'."
            } else{
                Write-Log -Level "INF" -Stage $stage -Message "Created Storage Container '$($tfContainerName)'."
            }
        }
    }
}

# Function: Create Entra ID Group for tenant contributor assignment.
function Create-EntraContributorGroup {
    $stage = "Configure-EntraID"
    $group = New-AzAdGroup -DisplayName $entraGroupName -Description $entraGroupDesc -MailNickname $entraGroupName
    if(!($group)){
        Write-Log -Level "ERR" -Stage $stage -Message "Failed to create Entra ID group. Abort."
        #exit 1
    } else{
        Write-Log -Level "INF" -Stage $stage -Message "Configured Entra ID group '$($group.DisplayName)'."
    }
    return $group
}

# Function: Create New/Update Existing Service Principal.
function Create-ServicePrincipal {
    $stage = "Configure-ServicePrincipal"
    # Check if existing Service Principal exists.
    $sp = Get-AzADServicePrincipal -DisplayName $servicePrincipalName -ErrorAction SilentlyContinue
    if(!($sp)){
        # Create new Service Principal if no existing one found.
        $sp = New-AzADServicePrincipal -DisplayName $servicePrincipalName -ErrorAction Stop
        if($sp){
            Write-Log -Level "INF" -Stage $stage -Message "Service Principal '$($sp.DisplayName)' created successfully."
        } else{
            Write-Log -Level "ERR" -Stage $stage -Message "Failed to create Service Principal. Abort."
            #exit 1
        }
    } else{
        $newSpCred = (New-AzADAppCredential -ApplicationId $sp.AppId -EndDate (Get-Date).AddYears(1) -ErrorAction Stop)
    }
    # Append to global results.
    $servicePrincipal = @{
        ServicePrincipalName = $sp.DisplayName
        ServicePrincipalAppId = $sp.AppId
        ServicePrincipalSecret = if($newSpCred){$newSpCred.SecretText}else{$sp.PasswordCredentials[0].SecretText}
    }
    return $servicePrincipal
}


#====================================================#
# VARIABLES
#====================================================#

# Script Variables
[string]$Global:scriptName = "Azure-Terraform-Bootstrapping" # Used for logfile naming.
[string]$Global:LoggingLocal = $true # Enable local logfile logging.
[string]$Global:LoggingLocalDir = "$env:USERPROFILE" # Local logfile path.

# Required applications
$requiredApps = @()
$requiredApps += [pscustomobject] @{Name = "Terraform"; Cmd = "terraform"; WinGetName = "Hashicorp.Terraform"}
$requiredApps += [pscustomobject] @{Name = "Azure CLI"; Cmd = "az"; WinGetName = "Microsoft.AzureCLI"}

# Required Powershell modules
$requiredPSModules = @("Az","Microsoft.Entra","Az.Subscription")

# Naming Conventions
$orgName = "Tim-Shand"
$orgPrefix = "tjs" # Short code name for the organization.
$primaryLocation = "australiaeast"
$ownerTeam = "CloudOps-Team" # DevOps-Team, CloudOps-Team
$environment = "prd" # prd, dev, tst
$project = "platform" # platform, workload, webapp, security
$service = "terraform" # terraform, ansible, kubernetes
$serviceShort = "tf" # tf, as, kb
$tags = @{
    owner = $ownerTeam;
    project = $project;
    environment = $environment;
    service = $service;
    created = (Get-Date -f 'yyyyMMddHHmmss');
    creator = "Bootstrap-Script";
}

# Entra ID
$entraGroupName = "Sec-RBAC-Global-Contributors-IAC"
$entraGroupDesc = "Security Group used by Service Principals for automating deployments."
$servicePrincipalName = "$orgPrefix-$project-$service-sp"

# Resources
$tfResourceGroupName = "$orgPrefix-$project-$service-rg" # Resource Group name
$tfStorageAccountName = "$orgPrefix$($project)$($serviceShort)$(Get-Random -Minimum 100000000 -Maximum 999999999)" # Random suffix, max 24 characters
$tfContainerName = "$orgPrefix-$project-$service-tfstate" # Blob Container name

#====================================================#
# MAIN SCRIPT EXECUTION
#====================================================#

# Check for running with admin privilages.
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")){
    Write-Log -Level "ERR" -Stage "Script" -Message "WARNING: You must run this script as Administrator."
    #exit 1
}
Write-Host "`r`n=============== Bootstrap Script: Azure Bootstrap Script ===============`r`n"
Write-Host "This script will create Azure resources necessary for Terraform bootstrapping.`r`n"
Write-Log -Level "INF" -Stage "START" -Message "Azure Bootstrap script started."

# Check required applications are installed.
$requiredAppCheck = Get-RequiredApps
if($requiredAppCheck -ge $requiredApps.Count){

    # Check required modules are installed.
    $requiredModuleCheck = Get-RequiredModules
    if($requiredModuleCheck -ge $requiredPSModules.Count){

        # Login to Azure.
        $azureAuthCheck = Get-AzureLogin
        if($azureAuthCheck){

            # Rename default subscripion for use as platform landing zone.
            $renameSub = Rename-DefaultSubscription

            # Create Entra ID group for tenant contributor role.
            $entraGroup = Create-EntraContributorGroup

            # Create Service Principal for Terraform/CI deployments.
            $servicePrincipal = Create-ServicePrincipal

            # Deploy Resources.
            #Create-TerraformResources

        } else{
            Write-Log -Level "ERR" -Stage $stage -Message "Failed Azure connection check. Abort."
            # exit 1
        }
    } else{
        Write-Log -Level "ERR" -Stage $stage -Message "Failed Powershell module check. Abort."
        # exit 1
    }
} else{
    Write-Log -Level "ERR" -Stage $stage -Message "Failed required applications check. Abort."
    # exit 1
}

# End
Write-Log -Level "INF" -Stage "END" -Message "Azure Bootstrap script completed."
Write-Host "`r`n=============== Bootstrap Script: Complete ===============`r`n"

# EOF