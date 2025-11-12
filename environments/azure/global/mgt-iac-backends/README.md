# Deployment: Azure IaC Backend Vending

This deployment uses a Terraform module to create Azure resources used for remote Terraform states. Using this method enables centralized storage of workload state files, located in a dedicated Azure subscription for IaC. 

Automatically provision required resources for new Terraform backends and secure CI/CD connectivity using a single Terraform module.  

- Dedicated Infrastructure-as-Code Azure subscription, with per-project containers in one storage account. 
- Automates the container and Service Principal OIDC authentication setup for new projects. 
- Container-level RBAC role assignments to manage access and permissions to state files. 

## Requirements
 
- **Azure Service Principal (Entra ID)**
  - Requires `Application.ReadWrite.All` API permission to allow the the Service Principal to update its own credential objects. 
- **Github PAT Token**
  - Added as repository secret, referenced by Github Actions worklflows. 
  - Requires read/write access to actions, actions variables, administration, code, environments, and secrets. 

## Actions

- Creates Azure storage account containers per project, centrally located in the Azure IaC subscription. 
- Creates new Github repository environment for the project. 
- Adds the `TF_BACKEND_CONTAINER` and `TF_BACKEND_KEY` variables to the Github repo environment to be used by the project backend configuration. 
- Adds a repo environment-specific federated credential (OIDC) to the Azure service principal. 

## Example

### Remote State Structure

```markdown
IaC Subscription: mgt-iac-sub
├── Resource Group: mgt-iac-state-rg
│   ├── Storage Account: mgtiacstatesa
│   │   ├── Container: tfstate-platform
│   │   ├── Container: tfstate-workload-app1
│   │   └── Container: tfstate-workload-app2

Platform Subscription: mgt-platform-sub
├── Landing Zone resources (network hub, policies, log analytics)

Workload Subscriptions (workload-sub-01)
├── App1 resources

Workload Subscriptions (workload-sub-02)
├── App2 resources
```

### Github Environment Variables

| Name             | Value                         | Environment                 |
| ----             | -----                         | -----------                 |
| TF_BACKEND_CN    | tfstate-azure-mgt-iac-core    | Azure-Platform-LandingZone  |
| TF_BACKEND_CN    | tfstate-azure-mgt-platformlz  | Azure-Platform-LandingZone  |
| TF_BACKEND_CN    | tfstate-azure-app-myapp01     | Azure-Workload-App01        |
