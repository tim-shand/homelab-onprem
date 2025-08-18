#======================================#
# Bootstrap: Azure Tenant (PowerShell) #
#======================================#

<# 
# DESCRIPTION:
Azure bootstrap script for remote Terraform backend.

# ACTIONS:
- Checks for necessary applications and PowerShell modules.
- Creates Entra ID group for assigning RBAC permissions.
- Creates a Service Principal for Azure DevOps/Terraform integration.
- Adds Service Principal to new Entra ID group.
- Assigns Entra ID group 'Contributor' rights to the Tenant Root management group.
- Creates a Terraform backend in Azure using Storage Account and Blob Container.
- Generates core Terraform files with variables, provider and backend configuration.
- [OPTIONAL] Adds Service Principal client secret to Github Actions.

# NOTE: 
Requires administrator privileges to run.

# USAGE:
.\scripts\bootstrap\bootstrap-azure-github.ps1
#>

#------------------------------------------------#
# VARIABLES
#------------------------------------------------#

# Required applications to be installed using WinGet.
$requiredApps = @()
$requiredApps += [pscustomobject] @{Name = "Terraform"; Cmd = "terraform"; WinGetName = "Hashicorp.Terraform"}
$requiredApps += [pscustomobject] @{Name = "Azure CLI"; Cmd = "az"; WinGetName = "Microsoft.AzureCLI"}
$requiredApps += [pscustomobject] @{Name = "Git"; Cmd = "git"; WinGetName = "Git.Git"}
$requiredApps += [pscustomobject] @{Name = "GitHub CLI"; Cmd = "gh"; WinGetName = "GitHub.cli"}

# Required Powershell modules.
$requiredPSModules = @("Az","Microsoft.Entra","Az.Subscription")

# Object for all results.
$orgPrefix = "tjs" # Short code name for the organization.
$location = "australiaeast"
$environment = "prd" # prd, dev, tst
$platform = "mgt" # app, infra, sec
$project = "platform" # platform, app, web
$service = "terraform" # terraform, ansible, kubernetes, security
$subNameNew = "$orgPrefix-$platform-$project-sub" # New subscription name.
$tags = @{ 
    environment = $environment;
    owner = "CloudOps";
    platform = $platform;
    project = $project;
    service = $service;
    created = (Get-Date -f 'yyyyMMddHHmmss');
    creator = "Bootstrap";
}
$entraGroupName = "Sec-Global-IAC-Contributors" # Entra ID group name for assigning RBAC 'Contributor' role to tenant root group.
$resourceGroupName = "$orgPrefix-$platform-$service-rg" # Resource Group name
$storageAccountName = "$orgPrefix$($platform)$($service)$(Get-Random -Minimum 10000000 -Maximum 99999999)" # Random suffix, max 24 characters
$containerName = "$orgPrefix-$platform-$service-tfstate" # Blob Container name
$servicePrincipalName = "$orgPrefix-$platform-$service-sp" # Service Principal name

#==========================================================================#
# FUNCTIONS
#==========================================================================#

# Function: Custom logging to local file or Event Log.
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("INF", "WRN", "ERR", "VER")]
        [string]$Level,
        [Parameter(Mandatory=$true)]
        [string]$LogStage,
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    # Set terminal colours
    switch ($Level){
        "INF" {$textColour = "Green"}
        "WRN" {$textColour = "Yellow"}
        "ERR" {$textColour = "Red"}
        "VER" {$textColour = "White"}
        default {$textColour = "White"}
    }
    # Write to console.
    Write-Host "$timestamp [$Level] | $LogStage | $Message" -ForegroundColor $textColour
}

# Function: Get OS and check script is run with admin priviliages.
function Get-OsAdminPrivs {
    if([System.Environment]::OSVersion.Platform -eq "unix"){
        if (!((id -u) -eq 0)) {
            Write-Log -Level "ERR" -LogStage "OS-Admin-Check" -Message "WARNING: You must run this script with admininstrator privilages. Abort."
            #exit 1
        }
    } 
    else{
        if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Write-Log -Level "ERR" -LogStage "OS-Admin-Check" -Message "WARNING: You must run this script with admininstrator privilages. Abort."
            #exit 1
        }
    }
}

# Function: Check for required applications.
function Get-RequiredApps($requiredApps) {
    $appResults = @()
    -LogStage = "Get-RequiredApps"
    Write-Log -Level "VER" -LogStage -LogStage -Message "Checking for required applications..."
    ForEach($app in $requiredApps) {        
        if (-not (Get-Command $app.Cmd -ErrorAction SilentlyContinue)) {
            Write-Log -Level "WRN" -LogStage -LogStage -Message "$($app.Name) is missing. Please install and re-run this script."
            $appResults += [pscustomobject] @{Name = "$($app.Name)"; Status = "Missing"}
        } 
        else {
            Write-Log -Level "INF" -LogStage -LogStage -Message "$($app.Name) is installed."
            $appResults += [pscustomobject] @{Name = "$($app.Name)"; Status = "Installed"}
        }
    }
    return $appResults
}

# Function: Check for required Powershell modules.
function Get-RequiredModules($requiredPSModules){
    $moduleResults = @()
    $logStage = "Get-RequiredModules"
    Write-Log -Level "VER" -LogStage $logStage -Message "Checking for required PowerShell modules..."
    ForEach($m in $requiredPSModules){
        if(!(Get-InstalledModule -Name $m -ErrorAction SilentlyContinue)){
            Write-Log -Level "WRN" -LogStage $logStage -Message "Module '$m' is not installed. Installing..."
            Try{
                Install-Module -Name $m -Repository PSGallery -Force -AllowClobber
                Write-Log -Level "INF" -LogStage $logStage -Message "Module '$m' installed successfully."
                $moduleResults += [pscustomobject] @{Name = "$($m)"; Status = "Installed"}
            }
            Catch{
                $err = $_.ExceptionMessage
                Write-Log -Level "ERR" -LogStage $logStage -Message "Module '$m' installation failed. Please install manually.`r`n$err"
                $moduleResults += [pscustomobject] @{Name = "$($m)"; Status = "Missing"}
            }
        } 
        else{
            Write-Log -Level "INF" -LogStage $logStage -Message "Module '$m' is already installed."
            $moduleResults += [pscustomobject] @{Name = "$($m)"; Status = "Installed"}
        }
    }
    return $moduleResults
}

# Function: Check login to Azure.
function Get-AzureLogin {
    # Check for existing Azure authentication, login if none.
    if(!((Get-AzContext).Account)){
        Connect-AzAccount
        $global:azSession = Get-AzContext

    } else{
        $global:azSession = Get-AzContext
        Write-Log -Level "INF" -LogStage "Get-AzureLogin" -Message "Logged in to Azure tenant [$($global:azSession.Account.Tenants)] as [$($global:azSession.Account.Id)]"
    }
}

# Function: Deploy Azure Service Principal (check for existing, create if missing).
$logStage = "Az-ServicePrincipal"
$sp = Get-AzADServicePrincipal -DisplayName $servicePrincipalName -ErrorAction SilentlyContinue
if(!($sp)){
    Try{
        # Create new Service Principal and assign a new client secret for auth.
        $sp = New-AzADServicePrincipal -DisplayName $servicePrincipalName `
            -Description "Bootstrap: Terraform Service Principal." `
            -Note "Bootstrap: Terraform Service Principal."
        $spCred = ($sp.PasswordCredentials.SecretText)
        Write-Log -Level "INF" -LogStage $logStage -Message "Service Principal created successfully."
    }
    Catch{
        $err = $_.Exception.Message
        Write-Log -Level "ERR" -LogStage $logStage -Message "Failed to locate or create required Service Principal. Abort.`r$err"
        #exit 1
    }
} else{
    # Service Principal already exists, remove existing credentials and create new.
    Try{
        Remove-AzADAppCredential -ApplicationId $sp.AppId
        $spCred = (New-AzADAppCredential -ApplicationId $sp.AppId -EndDate (Get-Date).AddYears(1))
        Write-Log -Level "INF" -LogStage $logStage -Message "Service Principal already exists. Reset client secret."
    }
    Catch{
        Write-Log -Level "WRN" -LogStage $logStage -Message "Failed to set client secret for existing Service Principal. Add manually. Proceeding."
    }
}

# Function: Create/Check Entra ID group for RBAC 'Contributor' role at tenant root management group.
$logStage = "EntraID-Group"
$entraGroup = Get-AzADGroup -DisplayName $entraGroupName
if(!($entraGroup)){
    # Create new Entra ID group.
    Try{
        $entraGroup = New-AzADGroup -DisplayName $entraGroupName -Description "Bootstrap: Entra ID group for IaC contributors." -MailNickname $entraGroupName
        Write-Log -Level "INF" -LogStage $logStage -Message "Entra ID group created successfully."
        # Add Service Principal to group.
        Try{
            $spGroupAdd = Add-AzADGroupMember -TargetGroupObjectId $entraGroup.Id -MemberObjectId $sp.Id
            Write-Log -Level "INF" -LogStage $logStage -Message "Added Service Principal to Entra ID group."
        }
        Catch{
            $err = $_.Exception.Message
            Write-Log -Level "ERR" -LogStage $logStage -Message "Failed to add Service Principal to Entra ID group. Abort.`r$err"
            #exit 1
        }
    }
    Catch{
        $err = $_.Exception.Message
        Write-Log -Level "ERR" -LogStage $logStage -Message "Failed to create Entra ID group for RBAC assignments. Abort.`r$err"
        #exit 1
    }
} else{
    Write-Log -Level "INF" -LogStage $logStage -Message "Entra ID group already exists."
}


<### TO DO ###

- Assign Entra Group to Tenent Root as Contributor.
- Create Terraform resources for backend.
- Populate Terraform files.

#>



# Assign Role: Assign 'Contributor' role to the service principal on the tenant root management group.
$rootMG = (Get-AzManagementGroup | Where-Object{$_.DisplayName -eq 'Tenant Root Group'} -ErrorAction SilentlyContinue)

if($rootMG) {
    $roleAssignment = New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Contributor" -Scope $rootMG.Id -ErrorAction Stop
    if ($roleAssignment) {
        Write-Log -Level "INF" -LogStage -LogStage -Message "Assigned 'Contributor' role to service principal '$servicePrincipalName' on management group '$($rootMG.DisplayName)'."
    } else {
        Write-Log -Level "ERR" -LogStage -LogStage -Message "Failed to assign role to service principal '$servicePrincipalName'."
        exit 1
    }
} else {
    Write-Log -Level "ERR" -LogStage -LogStage -Message "Management group '$rootMGName' not found."
    exit 1
}

     
    


#------------------------------------------------#
# MAIN SCRIPT EXECUTION
#------------------------------------------------#

Write-Host "`r`n=============== Bootstrap Script: Azure Bootstrap Script ===============`r`n"
Write-Host "This script will create resources necessary for deployments via Terraform.`r`n"
Write-Log -Level "VER" -LogStage "START" -Message "Azure Bootstrap script execution started."

# Check for OS administrator privileges.
Get-OsAdminPrivs

# Check for required apps and modules.
Get-RequiredApps($requiredApps)
Get-RequiredModules($requiredPSModules)

# Login to Azure.
Get-AzureLogin

# Deploy Resources.


# End
Write-Log -Level "VER" -LogStage "END" -Message "Utility script execution completed."
Write-Host "`r`n=============== Bootstrap Script: Complete ===============`r`n"
#Disconnect-AzAccount
# EOF