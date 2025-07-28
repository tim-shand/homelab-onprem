# Azure: Platform Landing Zone

This environment and associated Terraform code represents the Platform landing zone.  
The Platform landing zone provides core and shared services, such as connectivity, security and management.  

## Setup & Deployment

1. Run the Azure Bootstrap script (configures Service Principal, Entra Group, role assignments, populates Terraform files).
`./scripts/bootstrap/bootstrap-azure-tf.sh`  

2. Initialize Terraform using generated backend configuration file (required as variables not allowed yet).
`cd ./environments/azure/platform/ && terraform init -reconfigure --backend-config=backend.conf`  

3. Ensure Terraform code is valid by running some pre-checks.
`terraform fmt`: Ensures consistent code formatting.  
`terraform validate`: Checks the syntax and configuration validity.  

4. Run Terraform plan (output plan to file and human readable log file).
`terraform plan -out tfplan.plan && terraform show -no-color tfplan.plan > "tfplan_$(date +"%Y%m%d%H%M").log"`  

5. Run Terraform apply to deploy resources into Azure.
`terraform apply tfplan.plan`  

6. Run Terraform destroy (remove resources created by Terraform and clean up plan files).
`terraform destroy && rm -rf tfplan*`  
