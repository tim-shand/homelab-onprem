# Azure Settings.
location = "newzealandnorth" # Desired location for resources to be deployed in Azure.

# Naming Settings (used for resource names).
naming = {
    prefix = "tjs" # Short name of organization ("abc").
    platform = "wkl" # Platform name for related resources ("mgt", "plz").
    project = "testing" # Project name for related resources ("platform", "landingzone").
    service = "null" # Service name used in the project ("iac", "mgt", "sec").
    environment = "tst" # Environment for resources/project ("dev", "tst", "prd", "alz").
}

# Tags (assigned to all bootstrap resources).
tags = {
    Project = "Testing" # Name of the project the resources are for.
    Environment = "tst" # dev, tst, prd, alz
    Owner = "CloudOps" # Team responsible for the resources.
    Creator = "IaC" # Person or process that created the resources.
}
