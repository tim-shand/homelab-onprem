# SAFE TO COMMIT
# This file contains only non-sensitive configuration data (no credentials or secrets).
# All secrets are stored securely in Github Secrets or environment variables.

# Azure Settings.
location = "newzealandnorth" # Desired location for resources to be deployed in Azure.

# Naming Settings (used for resource names).
naming = {
    prefix = "tjs" # Short name of organization ("abc").
    platform = "mgt" # Platform name for related resources ("mgt", "plz").
    project = "platform" # Project name for related resources ("platform", "landingzone").
    service = "iac" # Service name used in the project ("iac", "mgt", "sec").
    environment = "prd" # Environment for resources/project ("dev", "tst", "prd", "alz").
}

# Tags (assigned to all bootstrap resources).
tags = {
    Project = "Platform" # Name of the project the resources are for.
    Environment = "prd" # dev, tst, prd, alz
    Owner = "CloudOps" # Team responsible for the resources.
    Creator = "Bootstrap" # Person or process that created the resources.
}

# GitHub Settings.
github_config = {
    org = "tim-shand" # Taken from current Github CLI session. 
    repo = "homelab" # Replace with your new desired GitHub repository name. Must be unique within the organization and empty.
    branch = "main" # Replace with your preferred branch name.
}
