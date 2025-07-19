# Azure Tenant Preparation Process

## To Do

- Currently failing the 'main' deployment.
- May revert to script or Terraform using Azure CLI auth.

---

The purpose of this process is to provision the initial Azure resources that will be used later on by Terraform. A Service Principal will be used to authenticate with Azure and provision resources within the tenant. Terraform will then use the created Storage Account for maintaining a [remote backend](https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli) state file.  

This provides several benefits, such as:

- **State Locking**
  - Prevents simultaneous operations that can corrupt the state file during deployments.
- **Security**
  - Protects sensitive values and secrets stored in state file from exposure.
- **Collaboration**
  - A shared remote backend allows teams to work on the same infrastructure, maintaining centralized consistency.
  - Makes it easier to integrate Terraform workflows into CI/CD pipelines by providing a central location for state files.

## Requirements

- Install [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)  
- Install Bicep CLI (`az bicep install`)
- Neccessary permissions to deploy resources in your Tenant  
  - Using an account with 'Global Admin', you will likely have no issues  
  - A less privilaged account may require additonal permissions
  - Check the [Microsoft Docs](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli) for further information  
- Enable: [Access management for Azure resources](https://learn.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin?tabs=azure-portal%2Centra-audit-logs) for user account running deployment  
- Add role "Owner" to current user account for Tenant root:  
`az role assignment create --scope '/' --role 'Owner' --assignee-object-id $(az ad signed-in-user show --query id --output tsv) --assignee-principal-type User`  

## A Few Notes on Bicep

_Note: The Microsoft Graph Bicep extension is currently in [preview](https://devblogs.microsoft.com/identity/bicep-templates-for-microsoft-graph-resources/)_

This process will be using the Microsoft Graph Bicep extension to deploy the initial Azure resources. For information on which resources are supported, check out the [Microsoft documentation](https://learn.microsoft.com/en-us/graph/templates/reference/overview?view=graph-bicep-1.0)  

**Bicep Overview:**

- Declarative, domain-specific (DSL) language native to Azure.
- Designed exclusively for infrastructure-as-code (IaC) deployments within the Azure ecosystem.
- Bicep provides access to the latest Azure (ARM) APIs.
- Stores deployment state in Azure, removing the need for maintaining external state files.

## Resource Creation

### Entra ID

- **Security Group**
  - Used to contain Service Principals
  - Group-level role assignments to subscription
- **App Registration**
  - Service Principal (added to above Security Group)
  - Client Secret (to be added to Key Vault)

### Resources

- **Resource Group**
  - Storage Account
    - Container
  - Azure Key Vault
    - Key Vault Secret

## Usage

### Step 1: Using Bicep _(Declarative)_

This step uses the Bicep files within this repo.  

1. Modify the parameter file 'main.bicepparam' to suit requirements.  
2. Validate the deployment template:  
`az deployment tenant validate --location australiaeast --template-file main.bicep --parameters main.bicepparam`  
3. Execute the 'Tenant' deployment, giving it a name using the command:  
`az deployment tenant create --name az_tenant_deploy --location australiaeast --template-file tenant.bicep --parameters tenant.bicepparam`  
4. Execute the 'Subscription' deployment, giving it a name using the command:  
`az deployment sub create --name az_resource_deploy --location australiaeast --template-file main.bicep --parameters main.bicepparam`  

### Step 2: Azure CLI _(Imperative)_

_This step is currently required as the 'PasswordCredential' method in the Graph extension is [not yet fully supported](https://learn.microsoft.com/en-us/graph/templates/limitations)._  

1. Login to the Azure tenant using Azure CLI.  
`az login`  
2. Set the target subscription.  
`az account set -s <id>`  
3. Generate a client secret for the app registration.  
`az ad app credential reset --id <appid from Bicep output> --append --display-name "tf-$(Get-Date -f 'yyyyMMddhhmmss')" --years 1`  
4. The command will output the client secret for use with Terraform.
