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
    subscription_id_env = "9173fb12-e761-49ab-8a72-fc4c578ff87b"
  }
}
