#=====================================================#
# Local Setup: Utility Script (Windows)
#=====================================================#

# DESCRIPTION:
# This script is designed to set up the local system for development.
# It includes functions to install necessary tools and configure settings.
# Will prompt the user to install missing applications and PowerShell modules.

# NOTE: 
# Requires administrator privileges to run.

# USAGE:
# .\scripts\utility\local-setup-windows.ps1 

#------------------------------------------------#
# VARIABLES
#------------------------------------------------#

# Global Variables
[string]$Global:scriptName = "LocalSystemSetup" # Used for log file naming.
[string]$Global:LoggingLocal = $true # Enable local log file logging.
[string]$Global:LoggingLocalDir = "$env:USERPROFILE" # Local log file log path.
[string]$Global:LoggingEventlog = $true # Enable Windows Eventlog logging.
[int]$Global:LoggingEventlogId = 900 # Windows Eventlog ID used for logging.

# Define list of required applications to be installed using WinGet.
$requiredApps = @()
$requiredApps += [pscustomobject] @{Name = "Terraform"; Cmd = "terraform"; WinGetName = "Hashicorp.Terraform"}
$requiredApps += [pscustomobject] @{Name = "Azure CLI"; Cmd = "az"; WinGetName = "Microsoft.AzureCLI"}
$requiredApps += [pscustomobject] @{Name = "Git"; Cmd = "git"; WinGetName = "Git.Git"}
$requiredApps += [pscustomobject] @{Name = "Fake-Test-App"; Cmd = "Fake-Test-App"; WinGetName = "Fake-Test-App"}
$requiredApps += [pscustomobject] @{Name = "GitHub CLI"; Cmd = "gh"; WinGetName = "GitHub.cli"}

# Define required Powershell modules.
$requiredPSModules = @("Az","Microsoft.Entra","Az.Subscription")

#------------------------------------------------#
# FUNCTIONS
#------------------------------------------------#

# Function: Check for script run with admin priviliages.
function Get-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        Write-Log -Level "ERR" -Stage "SCRIPT" -Message "WARNING: You must run this script as Administrator."
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
function Get-RequiredApps($requiredApps) {
    $stage = "Get-RequiredApps"
    Write-Log -Level "INF" -Stage $stage -Message "Checking for required applications..."
    ForEach($app in $requiredApps) {        
        if (-not (Get-Command $app.Cmd -ErrorAction SilentlyContinue)) {
            Write-Log -Level "WRN" -Stage $stage -Message "$($app.Name) is not installed."
            do {
                $userResponse = Read-Host -Prompt "The application '$($app.Name)' is not installed. Do you want to install it? (Y/N)"
                if ($userResponse -inotmatch "^(Y|N|y|n)$") {
                    Write-Log -Level "WRN" -Stage $stage -Message "Invalid response. Please enter 'Y' or 'N'."
                } else{
                    if ($userResponse -match "^(N|n)$") {
                        # Skip Install
                        Write-Log -Level "WRN" -Stage $stage -Message "Skipping installation of '$($app.Name)'."
                        return
                    } else{
                        # Install
                        Write-Log -Level "INF" -Stage $stage -Message "Proceeding with installation of '$($app.Name)'."
                        Invoke-Command -ScriptBlock {winget install --silent --exact --id $($app.WinGetName) `
                            --accept-source-agreements --accept-package-agreements --disable-interactivity}
                        if (-not (Get-Command $app.Cmd -ErrorAction SilentlyContinue)) {
                            Write-Log -Level "ERR" -Stage $stage -Message "$($app.Name) installation failed. Please install it manually."
                        } else {
                            Write-Log -Level "INF" -Stage $stage -Message "$($app.Name) installed successfully."
                        }
                    }
                }
            } while (
                # Repeat until a valid response is given.
                $userResponse -notmatch "^(Y|N|y|n)$"
            ) 
        } 
        else {
            Write-Log -Level "INF" -Stage $stage -Message "$($app.Name) is already installed."
        }
    }
}

# Function: Check for and install reuqired Powershell modules.
function Get-RequiredModules($requiredPSModules){
    $stage = "Get-RequiredModules"
    #Write-Host " - Checking for required PowerShell modules..."
    Write-Log -Level "INF" -Stage $stage -Message "Checking for required PowerShell modules..."
    ForEach($m in $requiredPSModules){
        if(!(Get-InstalledModule -Name $m -ErrorAction SilentlyContinue)){
            Write-Log -Level "WRN" -Stage $stage -Message "Module '$m' is not installed. Installing..."
            Try{
                Install-Module -Name $m -Repository PSGallery -Force -AllowClobber
                Write-Log -Level "INF" -Stage $stage -Message "Module '$m' installed successfully."
            }
            Catch{
                $err = $_.ExceptionMessage
                Write-Log -Level "ERR" -Stage $stage -Message "Module '$m' installation failed. Please install it manually.`r`n$err"
            }
        } 
        else{
            Write-Log -Level "INF" -Stage $stage -Message "Module '$m' is already installed."
        }
    }
}

#------------------------------------------------#
# MAIN SCRIPT EXECUTION
#------------------------------------------------#

Write-Host "`r`n=============== Utility Script: Local System Setup ===============`r`n"
Write-Host "This script will check and install missing required applications and modules.`r`n"
Write-Log -Level "INF" -Stage "START" -Message "Utility script execution is starting."

# Check for administrator privileges.
Get-Admin

# Check for required applications and modules, install if missing.
Get-RequiredApps($requiredApps)
Get-RequiredModules($requiredPSModules)

# End
Write-Log -Level "INF" -Stage "END" -Message "Utility script execution completed."
Write-Host "`r`n=============== Utility Script: Complete ===============`r`n"

# EOF