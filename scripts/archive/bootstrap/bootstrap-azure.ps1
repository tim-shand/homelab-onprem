#======================================#
# Bootstrap: Azure Tenant (PowerShell) #
#======================================#

<# 
# DESCRIPTION:
Azure bootstrap script for remote Terraform backend.

# ACTIONS:
- Checks for necessary applications and PowerShell modules.
- Creates Entra ID group for assigning RBAC permissions.
- Creates a Service Principal for CI/CD integration.
- Adds Service Principal to new Entra ID group.
- Assigns Entra ID group 'Contributor' rights to the Tenant Root management group.
- Creates a Terraform backend resources in Azure using Storage Account and Blob Container.
- Generates core Terraform files with variables, provider and backend configuration.

# NOTE: 
Requires administrator privileges to run.

# USAGE:
.\scripts\bootstrap\bootstrap-azure.ps1
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
$platform = "mgt" # app, infra, sec
$project = "platform" # platform, app, web
$service = "terraform" # terraform, ansible, kubernetes, security
$platformSubName = "$orgPrefix-$platform-$project-sub" # New subscription name.
$tags = @{ 
    environment = "prd";
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
$keyVaultName = "$orgPrefix-$platform-tf-$(Get-Random -Minimum 10000000 -Maximum 99999999)-kv" # KeyVault name to contain Service Principal secret 

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
    Write-Host "$timestamp [$Level] | $logStage | $message" -ForegroundColor $textColour
}

# Function: Get OS and check script is run with admin priviliages.
function Get-OsAdminPrivs {
    if([System.Environment]::OSVersion.Platform -eq "unix"){
        if (!((id -u) -eq 0)) {
            Write-Log -Level "ERR" -LogStage "OS-Admin-Check" -Message "WARNING: You must run this script with admininstrator privilages. Abort."
            exit 1
        }
    } 
    else{
        if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
            [Security.Principal.WindowsBuiltInRole] "Administrator")) {
            Write-Log -Level "ERR" -LogStage "OS-Admin-Check" -Message "WARNING: You must run this script with admininstrator privilages. Abort."
            exit 1
        }
    }
}

# Function: Check for required applications.
function Get-RequiredApps($requiredApps) {
    $appResults = @()
    $logStage = "Get-RequiredApps"
    Write-Log -Level "VER" -LogStage $logStage -Message "Checking for required applications..."
    ForEach($app in $requiredApps) {        
        if (-not (Get-Command $app.Cmd -ErrorAction SilentlyContinue)) {
            Write-Log -Level "WRN" -LogStage $logStage -Message " - $($app.Name) is missing. Please install and re-run this script."
            $appResults += [pscustomobject] @{Name = "$($app.Name)"; Type = "Application"; Status = "Missing"}
        } 
        else {
            Write-Log -Level "INF" -LogStage $logStage -Message " - $($app.Name) is installed."
            $appResults += [pscustomobject] @{Name = "$($app.Name)"; Type = "Application"; Status = "Installed"}
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
            Write-Log -Level "WRN" -LogStage $logStage -Message " - Module '$m' is not installed. Installing..."
            Try{
                Install-Module -Name $m -Repository PSGallery -Force -AllowClobber
                Write-Log -Level "INF" -LogStage $logStage -Message " - Module '$m' installed successfully."
                $moduleResults += [pscustomobject] @{Name = "$($m)"; Type = "PS Module"; Status = "Installed"}
            }
            Catch{
                $err = $_.ExceptionMessage
                Write-Log -Level "ERR" -LogStage $logStage -Message " - Module '$m' installation failed. Please install manually.`r`n`n$err"
                $moduleResults += [pscustomobject] @{Name = "$($m)"; Type = "PS Module"; Status = "Missing"}
            }
        } 
        else{
            Write-Log -Level "INF" -LogStage $logStage -Message " - Module '$m' is already installed."
            $moduleResults += [pscustomobject] @{Name = "$($m)"; Type = "PS Module"; Status = "Installed"}
        }
    }
    return $moduleResults
}

# Function: Check login to Azure.
function Get-AzureLogin {
    $logStage = "Get-AzureLogin"
    # Check for existing Azure authentication, login if none.
    if(!((Get-AzContext).Account)){
        Connect-AzAccount
        $global:azSession = Get-AzContext
    } 
    else{
        $global:azSession = Get-AzContext
        Write-Log -Level "INF" -LogStage $logStage -Message "Logged in to Azure tenant [$($global:azSession.Account.Tenants)] as [$($global:azSession.Account.Id)]"
    }
}

# Function: Deploy Azure Service Principal (check for existing, create if missing).
function Add-AzureSP {
    $logStage = "Create-ServicePrincipal"
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
            Write-Log -Level "ERR" -LogStage $logStage -Message "Failed to locate or create required Service Principal. Abort.`r`n$err"
            exit 1
        }
    } else{
        # Service Principal already exists, remove existing credentials and create new.
        Try{
            Remove-AzADAppCredential -ApplicationId $sp.AppId
            $spCred = (New-AzADAppCredential -ApplicationId $sp.AppId -EndDate (Get-Date).AddYears(1))
            Write-Log -Level "WRN" -LogStage $logStage -Message "Service Principal already exists. Reset client secret."
        }
        Catch{
            Write-Log -Level "WRN" -LogStage $logStage -Message "Failed to set client secret for existing Service Principal. Add manually. Skip."
        }
    }
    return $sp, $spCred
}

# Function: Create/Check Entra ID group for RBAC 'Contributor' role at tenant root management group.
function Add-EntraGroup ($sp) {
    $logStage = "EntraID-Group"
    $entraGroup = (Get-AzADGroup -DisplayName $entraGroupName -ErrorAction SilentlyContinue)
    if(!($entraGroup)){
        # Create new Entra ID group.
        Try{
            $entraGroup = New-AzADGroup -DisplayName $entraGroupName -Description "Bootstrap: Entra ID group for IaC contributors." -MailNickname $entraGroupName
            Write-Log -Level "INF" -LogStage $logStage -Message "Entra ID group created successfully."
        }
        Catch{
            $err = $_.Exception.Message
            Write-Log -Level "ERR" -LogStage $logStage -Message "Failed to create Entra ID group for RBAC assignments. Abort.`r`n$err"
            exit 1
        }
    } 
    else{
        Write-Log -Level "WRN" -LogStage $logStage -Message "Entra ID group already exists."
    }
    if($entraGroup){
        # Add current user and Service Principal to Entra ID group.
        $membersToAdd = @("$($sp.Id)","$((Get-AzADUser -UserPrincipalName (Get-AzContext).Account).Id)")
        ForEach($m in $membersToAdd){
            if(!(Get-AzADGroupMember -GroupObjectId $entraGroup.Id -Filter "id eq '$($m)'" -ErrorAction SilentlyContinue).DisplayName){
                # Not current member. Add to group.
                Try{
                    $spGroupAdd = Add-AzADGroupMember -TargetGroupObjectId $entraGroup.Id -MemberObjectId $m -ErrorAction Stop
                    Write-Log -Level "INF" -LogStage $logStage -Message "Added identity '$($m)' to Entra ID group '$($entraGroup.DisplayName)'."
                }
                Catch{
                    $err = $_.Exception.Message
                    Write-Log -Level "ERR" -LogStage $logStage -Message "Failed to add identity to Entra ID group. Abort.`r`n$err"
                    exit 1
                }
            }
            else{
                # Already a member.
                Write-Log -Level "WRN" -LogStage $logStage -Message "Identity '$($m)' is already a member of Entra ID group '$($entraGroup.DisplayName)'. Skip."
            }
        }
        return $entraGroup
    }
}

# Function: Assign 'Contributor' RBAC role for Entra ID group to the tenant root management group.
function Add-EntraGroupRBAC ($entraGroup) {
    $logStage = "Group-RBAC-Assignment"
    # Get tenant root management group object details.
    $rootMG = (Get-AzManagementGroup | Where-Object{$_.DisplayName -eq 'Tenant Root Group'})
    if(!($rootMG)){
        # Unable to read tenant root management group.
        Write-Log -Level "ERR" -LogStage $logStage -Message "Failed to obtain 'Tenant Root Group' details. Abort.`r`n$err."
        exit 1
    } 
    else{
        # Check role assignment first, as causes 'conflict' error message if already exists.
        if(!(Get-AzRoleAssignment -Scope $rootMG.Id -ObjectId $entraGroup.Id).RoleAssignmentName -eq "Contributor"){
            # Add 'Contributor' RBAC role for Entra ID group to the tenant root management group.
            Try{
                $roleAssignment = New-AzRoleAssignment -ObjectId $entraGroup.Id -RoleDefinitionName "Contributor" -Scope $rootMG.Id
                Write-Log -Level "INF" -LogStage $logStage -Message "Assigned 'Contributor' role to 'Tenant Root Group' for Entra ID group."
            }
            Catch{
                $err = $_.Exception.Message
                Write-Log -Level "ERR" -LogStage $logStage -Message "Failed to assign 'Contributor' role to Tenant Root Group for Entra ID group. Abort.`r`n$err"
                #exit 1
            }
        }
        else{
            # Role assignment already exists, skip.
            Write-Log -Level "WRN" -LogStage $logStage -Message "Role assignment 'Contributor' already exists for Entra ID group. Skip."
        }
    }
}

# Function: Deploy Terraform Resources.
function Add-TerraformRG ($resourceGroupName) {
    $logStage = "Resource-ResourceGroup"
    # Create Resource Group
    $rg = Get-AzResourceGroup -Name $resourceGroupName
    if(!($rg)){
        Try{
            # Create new Resource Group.
            $rg = New-AzResourceGroup -Name $resourceGroupName -Location $location -Tag $tags
            Write-Log -Level "INF" -LogStage $logStage -Message "Created new Resource Group '$($rg.ResourceGroupName)'."
        }
        Catch{
            $err = $_.Exception.Message
            Write-Log -Level "ERR" -LogStage $logStage -Message "Failed to create Resource Group. Abort.`r`n$err"
            exit 1
        }
    }
    else{
        # Resource Group already exists. Skip.        
        Write-Log -Level "WRN" -LogStage $logStage -Message "Resource Group '$($rg.ResourceGroupName)' already exists. Skip."
    }
    return $rg
}
    

# Function: Create Storage Account
function Add-TerraformSA ($resourceGroup) {
    $logStage = "Resource-StorageAccount"
    $sa = Get-AzStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroup.ResourceGroupName -ErrorAction SilentlyContinue
    if(!($sa)){
        Try{
            $sa = New-AzStorageAccount -ResourceGroupName $resourceGroup.ResourceGroupName `
                -Name $storageAccountName -Tag $tags -Location $resourceGroup.Location -SkuName Standard_LRS -ErrorAction Stop
            Write-Log -Level "INF" -LogStage $logStage -Message "Created new Storage Account '$($sa.StorageAccountName)'."
        }
        Catch{
            $err = $_.Exception.Message
            Write-Log -Level "ERR" -LogStage $logStage -Message "Failed to create Storage Account. Abort.`r`n$err"
            exit 1
        }
        Try{
            # Create Blob Container
            $storageContext = New-AzStorageContext $sa.StorageAccountName -UseConnectedAccount
            $blobCtn = Get-AzStorageContainer -Name $containerName -Context $storageContext -ErrorAction SilentlyContinue
            if(!($blobCtn)){
                $blobCtn = New-AzStorageContainer -Name $containerName -Context $storageContext -ErrorAction Stop
                Write-Log -Level "INF" -LogStage $logStage -Message "Created new Storage Container '$($blobCtn.Name)'."
            }
            else{
                Write-Log -Level "WRN" -LogStage $logStage -Message "Blob Container '$containerName' already exists. Skip."
            }
        }
        Catch{
            $err = $_.Exception.Message
            Write-Log -Level "ERR" -LogStage $logStage -Message "Failed to create Blob Container. Abort.`r`n$err"
            exit 1
        }
    }
    else{
        Write-Log -Level "WRN" -LogStage $logStage -Message "Storage Account '$($sa.StorageAccountName)' already exists. Skip."
    }
    return $sa, $blobCtn
}

# Function: Create Key Vault to contain Service Principal secret.
function Add-TerraformKV ($entraGroup, $resourceGroup, $sp) {
    $logStage = "Resource-KeyVault"
    # Get existing Key Vault, create new if not exists.
    $kv = Get-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $resourceGroup.ResourceGroupName -ErrorAction SilentlyContinue
    if(!($kv)){
        Try{
            # Create new Key Vault.
            $kv = New-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $location -Tag $tags -ErrorAction Stop
            Write-Log -Level "INF" -LogStage $logStage -Message "Created new Key Vault '$($kv.VaultName)'."
        }
        Catch {
            $err = $_.Exception.Message
            Write-Log -Level "ERR" -LogStage $logStage -Message "Failed to configure Key Vault. Abort.`r`n$err"
            exit 1
        }
    }
    # Check role assignment first, as causes 'conflict' error message if already exists.
    if(!(Get-AzRoleAssignment -Scope $kv.ResourceId -ObjectId $entraGroup.Id).RoleAssignmentName -eq "Key Vault Secrets Officer"){
        # Add required role 'Key Vault Secrets Officer' to Key Vault to allow modifications and reading.
        $kvRoleAssign = New-AzRoleAssignment -ObjectId $entraGroup.Id -RoleDefinitionName "Key Vault Secrets Officer" -Scope $kv.ResourceId -ErrorAction Stop
        Write-Log -Level "INF" -LogStage $logStage -Message "Added RBAC role 'Key Vault Secrets Officer' to Key Vault '$($kv.VaultName)' for Entra group '$($entraGroup.DisplayName)'."
    }
    else{
        # Role assignment already exists.
        Write-Log -Level "WRN" -LogStage $logStage -Message "RBAC role already assigned for Key Vault '$($kv.VaultName)'."
    }
    # Add Service Principal client secret to Key Vault.
    Try{
        $Secret = ConvertTo-SecureString -String "$($sp.SecretText)" -AsPlainText -Force -ErrorAction Stop
        $kvSecret = Set-AzKeyVaultSecret -VaultName "$($kv.VaultName)" -Name "$($sp.AppDisplayName)" -SecretValue $Secret -Tag $tags -ErrorAction Stop
        Write-Log -Level "INF" -LogStage $logStage -Message "Added Service Principal client secret value to Key Vault."
    }
    Catch{
        $err = $_.Exception.Message
        Write-Log -Level "ERR" -LogStage $logStage -Message "Failed to add Service Principal secret to Key Vault. Check RBAC. Skip.`r`n$err"
        exit 1
    }
    return $kv
}

#------------------------------------------------#
# MAIN SCRIPT EXECUTION
#------------------------------------------------#


<### TO DO ###

- Fix RBAC issues with Key Vault.
- Create Terraform resources for backend.
- Populate Terraform files.

#>

clear
Write-Host -ForegroundColor Cyan "`r`n=============== Bootstrap Script: Azure Bootstrap Script ===============`r`n"
Write-Host -ForegroundColor Cyan "This script will create resources necessary for deployments via Terraform.`r`n"

# Check for OS administrator privileges.
Get-OsAdminPrivs

# Check for required apps and modules.
$reqAppsResult = Get-RequiredApps($requiredApps)
$reqModulesResult = Get-RequiredModules($requiredPSModules)
$reqAppsResult += $reqModulesResult
$reqAppsResult | ft

# Login to Azure.
Get-AzureLogin

# Create Entra group, add SP and assign RBAC role to tenant root management group.
$sp = Add-AzureSP
$entraGrp = Add-EntraGroup -sp $sp
Add-EntraGroupRBAC -entraGroup $entraGrp

# Create Terraform Resources.
$resourceGroup = Add-TerraformRG -resourceGroupName $resourceGroupName
$storageAccount = Add-TerraformSA -resourceGroup $resourceGroup
$keyVault = Add-TerraformKV -entraGroup $entraGrp -resourceGroup $resourceGroup -sp $sp

# Output details.
Write-Host -ForegroundColor Cyan "`r`n=============== Bootstrap Script: Complete ===============`r`n"
Write-Host -ForegroundColor Cyan "---------------------------"
Write-Host -ForegroundColor Cyan "PLATFORM DETAILS:"
Write-Host -ForegroundColor Cyan "---------------------------"
Write-Host "* Tenant ID: $($Global:azSession.Tenant)"
Write-Host "* Subscription ID: $($Global:azSession.Subscription)"
Write-Host "* Contributors Group: $($entraGrp.DisplayName)"
Write-Host ""
Write-Host -ForegroundColor Cyan "---------------------------"
Write-Host -ForegroundColor Cyan "SERVICE PRINCIPAL:"
Write-Host -ForegroundColor Cyan "---------------------------"
Write-Host "* Name: $($sp.DisplayName)"
Write-Host "* AppID: $($sp.appId)"
Write-Host "* Secret: $($sp.SecretText)"
Write-Host ""
Write-Host -ForegroundColor Cyan "---------------------------"
Write-Host -ForegroundColor Cyan "TERRAFORM RESOURCES:"
Write-Host -ForegroundColor Cyan "---------------------------"
Write-Host "* Resource Group: $($resourceGroup.ResourceGroupName)"
Write-Host "* Storage Account: $($storageAccount.StorageAccountName)"
Write-Host "* Blob Container: $($storageAccount.Name)"
Write-Host "* Key Vault: $($keyVault.VaultName)"
Write-Host ""

#Disconnect-AzAccount
# EOF
