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
    subscription_id = "1234-1234-1234-1234"
  }
}
