# Terraform Variables

# Azure: Platform Variables
tf_tenant_id       = "123456-ABCD-7890-EFGH-1234ABCD"
tf_subscription_id = "123456-1234-ABCD-1234-123456789"
tf_client_id       = "123456-ABDC-1234-ABCD-123456789"
tf_client_secret   = "REDACTED"

# Naming Conventions (using validations)
default_location = "Australia East"
org_prefix       = "abc"       # Short code name for the organization
org_project      = "platform"  # platform, landingzone
org_service      = "terraform" # Terraform, Application, Ansible
org_environment  = "prd"

# Tag Values
tag_creator = "Bootstrap" # Creator of resources
tag_owner   = "CloudOps"  # Owner of the resources
