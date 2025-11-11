# Azure Bootstrapping: Terraform IaC Management with Github Actions

_Run-once Terraform deployment to bootstrap Azure environment for management via IaC using Github Actions._

This bootstrap deployment will create resources in both Azure and Github required for future deployments using Github Actions workflows. This allows for centralized storage of workload and platform project state files. This can be helpful when utilizing a monolithic style repository, as all project state files can be managed from the one location.  

## :green_book: Requirements

### Accounts

- **Azure:** Existing Azure account with `contributor` role assigned to a _dedicated_ subscription for IaC.
- **Github:** Existing Github account with a repository for the Azure project.

### Required Applications (Installed & Authenticated Locally)

- **[Terraform](https://developer.hashicorp.com/terraform/install):** Used to deploy resources to target Azure environment. 
- **[Azure CLI](https://learn.microsoft.com/en-us/cli/azure/?view=azure-cli-latest):** Required by Terraform `AzureRM` provider to connect to Azure. 
- **[Github CLI](https://cli.github.com/):** Connected and authenticated to target Github organization.  

## :hammer_and_wrench: Created Resources

- **Entra ID: Service Principal (App Registration)**
  - Dedicated, privileged identity for executing changes in the Azure tenant. 
  - Uses federated credentials (OIDC) for authentication with Github Actions workflows.
- **Github: Repository Secrets and Variables**
  - Adds Entra ID service principal details to repository secrets and variables. 
- **Azure: Remote Backend Resources**
  - Uses dedicated Azure subscription to contain remote states for all IaC projects.
  - **Resource Group:** Logical container for IaC related resources. 
  - **Storage Account:** Holds all storage containers in one account. 
  - **Containers:** Logical grouping of remote states per IaC project. 

## :gear: Process

1. Install and authenticate required applications.
2. Obtain Azure subscription ID for dedicated IaC subscription.
3. Execute Terraform commands using IaC subscription ID variable input.
4. Verify all resources have been deployed in Azure and Github. 
5. Modify Terraform `providers.tf` file, comment out existing `backend "local"` block.
6. Uncomment `backend "AzureRM"` block and populate with newly created resource names.
7. Migrate Terraform backend from local, to the new Azure IaC backend location.

## :arrow_forward: Usage

- Update TFVARS file with required Github configuration and Azure naming/tagging values.
- **:rotating_light: NOTE:** Make sure to **NEVER** store sensitive values in the TFVARS file if committing to public repository.

### Deployment

1. Set both Azure tenant ID and subscription ID as bash variables.

```shell
# Set subscription ID for IaC as variable.
TENANT_ID="1234-1234-1234-1234"
SUBSCRIPTION_ID_IAC="1234-5678-1234-5678"
echo -e "Tenant: $TENANT_ID \nSubscription: $SUBSCRIPTION_ID_IAC"
```

2. Configure (initialize) Terraform. Downloads and installed required providers.

```shell
# Terraform: Initialize (setup required providers).
terraform -chdir=environments/azure/bootstrap init
```

3. Validate Terraform code to check for errors and ensure syntax is correct.

```shell
# Terraform: Validate (verify code syntax and consistency).
terraform -chdir=environments/azure/bootstrap validate
```

4. Generate a Terraform plan file, passing in bash variables. This will display terminal output of intended changes.

```shell
# Terraform: Plan (generate plan file of intended changes).
terraform -chdir=environments/azure/bootstrap plan -out=bootstrap.tfplan -var-file=bootstrap.tfvars \
-var="tenant_id=$TENANT_ID" \
-var="subscription_id_iac=$SUBSCRIPTION_ID_IAC"
```

5. Deploy Terraform resources using the plan file created in previous step.

```shell
# Terraform: Apply (deploy changes from plan file).
terraform -chdir=environments/azure/bootstrap apply bootstrap.tfplan
```

### Removal/Destroy (OPTIONAL)

_Useful for validating the deployment/destroy process, but not required._

1. To remove the newly deployed resources, execute the following:

```shell
# [OPTIONAL] Terraform: Destroy (Remove all deployed changes made from plan file).
terraform -chdir=environments/azure/bootstrap destroy -var-file=bootstrap.tfvars \
-var="tenant_id=$TENANT_ID" \
-var="subscription_id_iac=$SUBSCRIPTION_ID_IAC"
```

### Migration

1. Edit Terraform `providers.tf` file.
2. Comment out the existing `backend "local"` block and uncomment the `backend "azurerm"` block.

```hcl
  # backend "local" {
  #   path = "azure-mgt-iac-bootstrap.tfstate" # Used for initial bootstrapping process.
  # }
  backend "azurerm" {} # Use dynamic backend supplied via inline command.
```

3. Migrate the local Terraform state to newly created Azure resources.

```shell
# Set shell variables to Terraform outputs.
ARM_BACKEND_RG="[RESOURCE_GROUP_NAME]" \
ARM_BACKEND_SA="[STORAGE_ACCOUNT_NAME]" \
ARM_BACKEND_CN="[STORAGE_ACCOUNT_CONTAINER_NAME]" \
ARM_BACKEND_KEY="azure-mgt-iac-bootstrap.tfstate"
echo -e "RG: $ARM_BACKEND_RG \nSA: $ARM_BACKEND_SA \nCN: $ARM_BACKEND_CN \nKEY: $ARM_BACKEND_KEY"

# Migrate local state to Azure backend.
terraform -chdir=environments/azure/bootstrap init -migrate-state -force-copy -input=false \
-backend-config="resource_group_name=$ARM_BACKEND_RG" \
-backend-config="storage_account_name=$ARM_BACKEND_SA" \
-backend-config="container_name=$ARM_BACKEND_CN" \
-backend-config="key=$ARM_BACKEND_KEY"
```

5. Clean up local files (no longer required post-migration).

```shell
# Remove local Terraform files, no longer required. 
rm -r environments/azure/bootstrap/.terraform \
environments/azure/bootstrap/.terraform.* \
environments/azure/bootstrap/*.tfstate* \
environments/azure/bootstrap/*.tfplan
```

---
