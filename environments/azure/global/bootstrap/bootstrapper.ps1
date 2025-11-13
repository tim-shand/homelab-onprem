<#
#======================================#
# Bootstrap: Azure (PowerShell)
#======================================#

# DESCRIPTION:
Bootstrap script to prepare Azure tenant for management via Terraform and Github Actions.
This script performs the following tasks:
- Checks for required local applications (Azure CLI, Terraform, GitHub CLI).
- Checks for local environment variables file (env.psd1) and imports configuration.
- Validates Azure CLI authentication, uses Azure tenant ID from current session.
- Validates Github CLI authentication, confirms access to provided repository.
- Generates Terraform variable file (TFVARS) from local script variables.
- Initializes and applies Terraform configuration to create bootstrap resources in Azure.

# USAGE:
./bootstrap-azure-tf-gh.ps1
./bootstrap-azure-tf-gh.ps1 -destroy
#>

#=============================================#
# VARIABLES
#=============================================#

# General Settings/Variables.
param(
    [Parameter(Mandatory=$true)][string]$AzureSubscriptionIaC, # Azure subscription for IaC.
    [switch]$destroy # Add switch parameter for delete option.
)
#$workingDir = "$((Get-Location).Path)/environments/azure/global/bootstrap" # Working directory for Terraform files
$workingDir = "$((Get-Location).Path)\environments\azure\global\bootstrap" # Working directory for Terraform files

# Required applications.
$requiredApps = @(
    [PSCustomObject]@{ Name = "Azure CLI"; Command = "az" }
    [PSCustomObject]@{ Name = "Terraform"; Command = "terraform" }
    [PSCustomObject]@{ Name = "GitHub CLI"; Command = "gh" }
)

# Determine request action and populate hashtable for logging purposes.
if($destroy){
    $sys_action = @{
        do = "Remove"
        past = "Removed"
        current = "Removing"
        colour = "Magenta"
    }
}
else{
    $sys_action = @{
        do = "Create"
        past = "Created"
        current= "Creating"
        colour = "Green"
    }
}

# Azure Settings.
$location = "newzealandnorth" # Desired location for resources to be deployed in Azure.

# Naming Settings (used for resource names).
$naming = @{
    prefix = "tjs" # Short name of organization ("abc").
    platform = "mgt" # Platform type: ("plz", "app", "mgt").
    service = "iac" # Service name used in the project ("gov", "con", "sec", "sys").
    project = "platform" # Project name for related resources ("platform", "webapp01").
    environment = "prd" # Environment for resources/project ("dev", "tst", "prd").
}

# Tags (assigned to all bootstrap resources).
$tags = @{
    Project = "Platform" # Name of the project the resources are for.
    Environment = "prd" # dev, tst, prd
    Owner = "CloudOps" # Team responsible for the resources.
    Creator = "Bootstrap" # Person or process that created the resources.
}

# Github Settings.
$github_config = @{
    org = "tim-shand" # Github organization where repository is located.
    repo = "homelab" # Github repository to use for adding secrets and variables.
    branch = "main" # Using main branch of repository.
}

#=============================================#
# FUNCTIONS
#=============================================#

# Function: Custom logging with terminal colours and timestamp etc.
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("INF", "WRN", "ERR", "SYS")]
        [string]$Level,
        [Parameter(Mandatory=$true)]
        [string]$Message
    )    
    # Set terminal colours based on level parameter.
    switch ($Level){
        "INF" {$textColour = "Green"}
        "WRN" {$textColour = "Yellow"}
        "ERR" {$textColour = "Red"}
        "SYS" {$textColour = "White"}
        default {$textColour = "White"}
    }
    # Write to console.
    if($level -eq "SYS"){
        Write-Host "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) | [$Level] | $message" -ForegroundColor $textColour -NoNewline
    }
    else{
        Write-Host "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) | [$Level] | $message" -ForegroundColor $textColour
    } 
}

# Function: User confirmation prompt, can be re-used for various stages.
function Get-UserConfirm {
    while ($true) {
        $userConfirm = (Read-Host -Prompt "Do you wish to proceed [Y/N]?")
        switch -Regex ($userConfirm.Trim().ToLower()) {
            "^(y|yes)$" {
                return $true
            }
            "^(n|no)$" {
                Write-Log -Level "WRN" -Message "- User declined to proceed."
                return $false
            }
            default {
                Write-Log -Level "WRN" -Message "- Invalid response. Please enter [Y/Yes/N/No]."
            }
        }
    }
}

#=============================================#
# MAIN: Validations & Pre-Checks
#=============================================#

# Clear the console and generate script header message.
Clear-Host
Write-Host -ForegroundColor Cyan "`r`n==========================================================================="
Write-Host -ForegroundColor Magenta "                Bootstrap Script: Azure | Terraform | Github                "
Write-Host -ForegroundColor Cyan "===========================================================================`r`n"
Write-Host -ForegroundColor Cyan "*** Performing Initial Checks & Validations"

# Validate: Check install status for required applications.
Write-Log -Level "SYS" -Message "Check: Required applications... "
ForEach($app in $requiredApps) {
    Try{
        # Attempt to get the command for each application to test if installed.
        Get-Command $app.Command > $null 2>&1
    }
    Catch{
        Write-Host "FAIL" -ForegroundColor Red
        Write-Log -Level "ERR" -Message "- Required application '$($app.Name)' is missing. Please install and try again."
        exit 1
    }
} 
Write-Host "PASS" -ForegroundColor Green

# Validate: Github CLI authentication. Check for existing authenticated session.
Write-Log -Level "SYS" -Message "Check: Validate Github CLI authenticated session... "
Try{
    $ghSession = gh api user 2>$null | ConvertFrom-JSON
    Write-Host "PASS" -ForegroundColor Green
    Write-Log -Level "INF" -Message "- Github CLI logged in as: $($ghSession.login) [$($ghSession.html_url)]"

    # Check if repository exists. 
    $gh_org = ($ghSession.html_url).Replace("https://github.com/","")
    if(-not ($destroy) ){
        $repoCheck = (gh repo list --json name | ConvertFrom-JSON)
        if ($repoCheck | Where-Object {$_.name -eq "$($github_config.repo)"} ) {
            Write-Log -Level "INF" -Message "- Repository '$($gh_org)/$($github_config.repo)' is accessible."
        }
        else{
            Write-Log -Level "ERR" -Message "- Failed to access provided repository. Please check name is correct. Abort."
            exit 1
        }
    }
}
Catch{
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message "- Failed GitHub CLI authentication check. Please run 'gh auth login' and try again."
    exit 1
}

# Validate: Azure CLI authentication. Check for existing authenticated session.
Write-Log -Level "SYS" -Message "Check: Validate Azure CLI authenticated session... "
$azCheck = $( az account show --only-show-errors )
if(-not ( $azCheck ) ){
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message "- Failed Azure CLI authentication check. Please run 'az login' manually and try again."
    exit 1
}
else{
    Write-Host "PASS" -ForegroundColor Green
    $azSession = az account show --only-show-errors 2>&1 | ConvertFrom-JSON
    Write-Log -Level "INF" -Message "- Current User: $($azSession.user.name)"
    Write-Log -Level "INF" -Message "- Azure Tenant: $($azSession.tenantDefaultDomain) [$($azSession.tenantId)]"
    Write-Log -Level "INF" -Message "- Subscription: $($azSession.name) [$($azSession.id)]"
}

#================================================#
# MAIN: Stage 2 - Display Intended Actions
#================================================#

Write-Host "`r`nWorking Directory: $workingDir"
Write-Host "Target Azure Environment:" -ForegroundColor Cyan
Write-Host "- Tenant ID: $($azSession.tenantId)"
Write-Host "- Subscription ID: $($azSession.id)"
Write-Host "- Subscription Name: $($azSession.name)"
Write-Host "- Location: $($location)"
Write-Host ""
Write-Host "The following resources will be " -ForegroundColor Cyan -NoNewLine
Write-Host "$(($sys_action.past).ToUpper()):" -ForegroundColor $sys_action.colour

Write-Host "- Github: $gh_org/$($github_config.repo)" -ForegroundColor Yellow
Write-Host "  - Secrets: Used by workflows for authentication."
Write-Host "  - Variables: Used by workflows for Terraform remote backend."
Write-Host "- Azure:" -ForegroundColor Yellow
Write-Host "  - Entra ID Service Principal: $($naming.prefix)-$($naming.platform)-$($naming.service)-sp"
if($destroy){
    Write-Host "  - Resource Group: $($naming.prefix)-$($naming.platform)-$($naming.service)-rg" -NoNewline
    Write-Host " (** INCLUDES ALL CHILD RESOURCES **)" -ForegroundColor $sys_action.colour
}
else{
    Write-Host "  - Resource Group: $($naming.prefix)-$($naming.platform)-$($naming.service)-rg"
    Write-Host "  - Storage Account: $($naming.prefix)$($naming.platform)$($naming.service)***** (determined during deployment uses random integers)."
    Write-Host "  - Storage Container: tfstate-azure-$($naming.project)"
}
Write-Host ""
Write-Log -Level "WRN" -Message "The above resources will be $(($sys_action.past).ToLower()) in the target environment."
if(-not (Get-UserConfirm) ){
    Write-Log -Level "ERR" -Message "User aborted process. Please confirm intended configuration and try again."
    exit 1
} 

#================================================#
# MAIN: Stage 3 - Prepare Terraform
#================================================#

# Generate TFVARS file.
$tfVARS = @"
# SAFE TO COMMIT
# This file contains only non-sensitive configuration data (no credentials or secrets).
# All secrets are stored securely in Github Secrets or environment variables.

# Azure Settings.
location = "$($location)" # Desired location for resources to be deployed in Azure.

# Naming Settings (used for resource names).
naming = {
    prefix = "$($naming.prefix)" # Short name of organization ("abc").
    platform = "$($naming.platform)" # Platform name for related resources ("mgt", "plz").
    project = "$($naming.project)" # Project name for related resources ("platform", "landingzone").
    service = "$($naming.service)" # Service name used in the project ("iac", "mgt", "sec").
    environment = "$($naming.environment)" # Environment for resources/project ("dev", "tst", "prd", "alz").
}

# Tags (assigned to all bootstrap resources).
tags = {
    Project = "$($tags.project)" # Name of the project the resources are for.
    Environment = "$($tags.environment)" # dev, tst, prd, alz
    Owner = "$($tags.owner)" # Team responsible for the resources.
    Creator = "$($tags.creator)" # Person or process that created the resources.
    Deployment = "$(Get-Date -f "yyyyMMdd.HHmmss")" # Timestamp for identifying deployment.
}

# GitHub Settings.
github_config = {
    org = "$($gh_org)" # Taken from current Github CLI session. 
    repo = "$($github_config.repo)" # Replace with your new desired GitHub repository name. Must be unique within the organization and empty.
    branch = "$($github_config.branch)" # Replace with your preferred branch name.
}
"@
# Write out TFVARS file (only if not already exists).
if(-not (Test-Path -Path "$workingDir/bootstrap.tfvars") ){
    $tfVARS | Out-File -Encoding utf8 -FilePath "$workingDir/bootstrap.tfvars" -Force
}

# Terraform: Initialize
Write-Log -Level "SYS" -Message "Performing Action: Initialize Terraform configuration... "
if(terraform -chdir="$($workingDir)" init -upgrade){
    Write-Host "PASS" -ForegroundColor Green
} else{
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message "- Terraform initialization failed. Please check configuration and try again."
    exit 1
}

# Terraform: Validate
Write-Log -Level "SYS" -Message "Performing Action: Running Terraform validation... "
if(terraform -chdir="$($workingDir)" validate){
    Write-Host "PASS" -ForegroundColor Green
} else{
    Write-Host "FAIL" -ForegroundColor Red
    Write-Log -Level "ERR" -Message "- Terraform validation failed. Please check configuration and try again."
    exit 1
}

#===================================================#
# MAIN: Stage 4 - Execute Terraform (Deploy/Destroy)
#===================================================#

if($destroy){
    # Terraform: Destroy
    Write-Log -Level "WRN" -Message "Terraform will now remove all bootstrap resources. This may take several minutes to complete."
    if(-not (Get-UserConfirm) ){
        Write-Log -Level "ERR" -Message "User aborted process. Please confirm intended configuration and try again."
        exit 1
    }
    else{
        Write-Log -Level "SYS" -Message "Performing Action: Running Terraform destroy... "
        if(terraform -chdir="$($workingDir)" destroy --auto-approve `
            -var-file="bootstrap.tfvars" `
            -var="azure_tenant_id=$($azSession.tenantId)" `
            -var="platform_subscription_id=$($azSession.id)" `
            -var="github_org=$($gh_org)"
        ){
            Write-Host "PASS" -ForegroundColor Green
            Write-Host -ForegroundColor Cyan "`r`n*** Bootstrap Removal Complete! ***`r`n"
        } else{
            Write-Host "FAIL" -ForegroundColor Red
            Write-Log -Level "ERR" -Message "- Terraform plan failed. Please check configuration and try again."
            exit 1
        }
    }
}
else{
    # Terraform: Plan
    Write-Log -Level "SYS" -Message "Performing Action: Running Terraform plan... "
    if(terraform -chdir="$($workingDir)" plan --out=bootstrap.tfplan `
            -var-file="bootstrap.tfvars" `
            -var="tenant_id=$($azSession.tenantId)" `
            -var="subscription_id_iac=$($azSession.id)"
    ){
        Write-Host "PASS" -ForegroundColor Green
        terraform -chdir="$($workingDir)" show "$workingDir/bootstrap.tfplan"
    } else{
        Write-Host "FAIL" -ForegroundColor Red
        Write-Log -Level "ERR" -Message "- Terraform plan failed. Please check configuration and try again."
        exit 1
    }

    # Terraform: Apply
    if(Test-Path -Path "$workingDir/bootstrap.tfplan"){
        Write-Host ""
        Write-Log -Level "WRN" -Message "Terraform will now deploy resources. This may take several minutes to complete."
        if(-not (Get-UserConfirm) ){
            Write-Log -Level "ERR" -Message "User aborted process. Please confirm intended configuration and try again."
            exit 1
        }
        else{
            Write-Log -Level "SYS" -Message "Performing Action: Running Terraform apply... "
            if(terraform -chdir="$($workingDir)" apply bootstrap.tfplan){
                Write-Host "PASS" -ForegroundColor Green
            } else{
                Write-Host "FAIL" -ForegroundColor Red
                Write-Log -Level "ERR" -Message "- Terraform plan failed. Please check configuration and try again."
                exit 1
            }
        }
    } else{
        Write-Log -Level "ERR" -Message "- Terraform plan file missing! Please check configuration and try again."
        exit 1  
    }
}

#================================================#
# MAIN: Stage 5 - Migrate State to Azure
#================================================#

if(-not ($destroy)){
    # Get Github variables from Terraform output.
    Write-Log -Level "SYS" -Message "Retrieving Terraform backend details from output... "
    Try{
        $tf_rg = terraform -chdir="$($workingDir)" output -raw out_bootstrap_iac_rg
        $tf_sa = terraform -chdir="$($workingDir)" output -raw out_bootstrap_iac_sa
        $tf_cn = terraform -chdir="$($workingDir)" output -raw out_bootstrap_iac_cn
        Write-Host "PASS" -ForegroundColor Green
    }
    Catch{
        Write-Host "FAIL" -ForegroundColor Red
        Write-Log -Level "ERR" -Message "- Failed to get Terraform output values. Please check configuration and try again."
        exit 1
    }

    # Generate backend config for state migration.
    $tfBackend = `
@"
terraform {
    backend "azurerm" {
        resource_group_name  = "$($tf_rg)"
        storage_account_name = "$($tf_sa)"
        container_name       = "$($tf_cn)"
        key                  = "azure-bootstrap.tfstate"
    }
}
"@
    $tfBackend | Out-File -Encoding utf8 -FilePath "$workingDir\backend.tf" -Force

    # Terraform: Migrate State
    Write-Log -Level "WRN" -Message "Terraform will now migrate state to Azure."
    if(Get-UserConfirm){
        Write-Log -Level "SYS" -Message "Migrating Terraform state to Azure... "
        if(terraform -chdir="$($workingDir)" init -migrate-state -force-copy -input=false){
            Write-Host "PASS" -ForegroundColor Green
        }
        else{
            Write-Host "FAIL" -ForegroundColor Red
            Write-Log -Level "ERR" -Message "- Failed to migrate Terraform state to Azure."
        }
    }
    else{
        Write-Log -Level "WRN" -Message "- Terraform state migration aborted by user."
        exit 1
    }
}

#================================================#
# MAIN: Stage 6 - Clean Up
#================================================#

Remove-Item -Path "$workingDir\backend.tf" -Force
Remove-Item -Path "$workingDir\bootstrap.*" -Force
Remove-Item -Path "$workingDir\.terraform*" -Recurse -Force
Remove-Item -Path "$workingDir\*.tfstate*" -Force
