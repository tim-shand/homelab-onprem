#! /bin/bash

#=====================================================#
# Local Setup: Utility Script (Linux) [Debian, Ubuntu]
#=====================================================#

# DESCRIPTION:
# This script is designed to set up the local system for development.
# It includes functions to install necessary tools and configure settings.

# NOTE: 
# Requires administrator (sudo) privileges to run.

# USAGE:
# ./scripts/utility/local-setup-linux.sh

#------------------------------------------------#
# VARIABLES
#------------------------------------------------#

# Global Variables
scriptName="LocalSystemSetup" # Used for log file naming.
LoggingLocal=true # Enable local log file logging.
LoggingLocalDir="~/$scriptName""_$(date +%Y%m%d%H%M).log" # Local log file log path.

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color / Reset

# Define list of required applications to be installed.
requiredApps="jq git terraform gh curl"

#------------------------------------------------#
# FUNCTIONS
#------------------------------------------------#

# Function: Install required applications.
installRequiredApps() {
    echo " - Checking for required applications..."
    for app in $requiredApps; do
        if ! command -v $app &> /dev/null; then
            echo -e "${YELLOW}WARN: $app is not installed. Installing..."
            sudo apt-get install -y $app &> /dev/null
            # Test app is installed
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
        echo -e "${GREEN}INFO: Azure CLI is already installed.${NC}"
    fi
}

#------------------------------------------------#
# MAIN SCRIPT EXECUTION
#------------------------------------------------#
echo
if [ "$LocalLogging"== "true" ]; then
    exec > >(tee -a "$LoggingLocalDir") 2>&1 # Redirect all output (stdout and stderr) through tee.
fi
echo
echo -e "${YELLOW}=============== Utility Script: Local System Setup ==============${NC}"
echo -e "${YELLOW}This script will check and install missing required applications.${NC}"
echo

# Check if the script is run with root privileges.
if [ "$EUID" -ne 0 ]; then
  echo "WARNING: SCript requires to be run with root privileges (sudo)."
  echo "Please run the script with 'sudo ./scripts/local/local-setup-linux.sh'."
  echo "Exiting..."
  exit 1
fi

# Call the function to install required applications.
installRequiredApps

echo
echo -e "${YELLOW}=============== Utility Script: Complete ===============${NC}"
echo
# EOF