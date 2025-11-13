#=================================================================#
# Vending: Azure IaC Backends
#=================================================================#

# Github Configuration.
github_config = {
  owner = "tim-shand"
  repo = "homelab"
}

# Object of projects that require IaC backend.
projects = {
  "azure-workload-test" = { 
    create_github_env = true
    subscription_id_env = "66f229bc-adb1-4b24-be8d-bd2a9b471336"
  }
}
