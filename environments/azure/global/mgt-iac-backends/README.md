# Deployment: Azure IaC Backend Vending

This deployment uses a Terraform module to create Azure resources used for remote Terraform states. Using this method enables centralized storage of workload state files, located in a dedicated Azure subscription for IaC. 

Automatically provision required resources for new Terraform backends and secure CI/CD connectivity using a single Terraform module.  

- Dedicated Infrastructure-as-Code Azure subscription, with per-project containers in one storage account. 
- Automates the container and Service Principal OIDC authentication setup for new projects. 
- Container-level RBAC role assignments to manage access and permissions to state files. 

## Requirements
 
- Azure Service Principal - API Permissions: `Application.ReadWrite.All`. 
- Github OAuth Token: Added to repository secrets, referenced by Github Actions worklflow. 

## Actions

- Creates Azure Storage Account containers per project, located in the Azure IaC subscription. 
- Adds the `TF_BACKEND_CONTAINER` variable to the specified Github repo environment. 
- Adds a repo environment-specific federated credential (OIDC) to the service principal. 

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
