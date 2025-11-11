# Deployment: Azure IaC Backends

This deployment uses a Terraform module to create Azure resources used for remote Terraform states. Using this method enables centralized storage of workload state files, located in a dedicated Azure subscription for IaC. 

Automatically provision required resources for new Terraform backends and secure CI/CD connectivity using a single Terraform module.  

- Dedicated Infrastructure-as-Code Azure subscription, with per-project containers in one storage account. 
- Automates the container and Service Principal OIDC authentication setup for new projects. 
- Container-level RBAC role assignments to manage access and permissions to state files. 

## Requirements
 
- Azure Service Principal - API Permissions: `Application.ReadWrite.All`, `Directory.ReadWrite.All`. 
- Github OAuth Token: Added to repository secrets, referenced by Github Actions worklflow. 

## Actions

- Creates Azure Storage Account containers per project, located in the Azure IaC subscription. 
- Adds the `ARM_IAC_BACKEND_CN` variable to the specified Github repo environment. 
- Adds a repo environment-specific federated credential (OIDC) to the service principal. 

## Example

```markdown
+---------------------------------------------------------+
| Subscription: mgt-iac-sub                               |
|                                                         |
|  ├── mgt-iac-state-rg (Resource Group)                  |
|  │    ├── mgtiacstatesa (Storage Account)               |
|  │    │    ├── Container: tfstate-azure-mgt-iac-core    |
|  │    │    │    ├── azure-mgt-iac-core.tfstate          |
|  │    │    ├── Container: tfstate-azure-mgt-platformlz  |
|  │    │    │    ├── azure-mgt-platformlz.tfstate        |
|  │    │    ├── Container: tfstate-azure-app             |
|  │    │    │    ├── azure-app.tfstate                   |
|                 ...                                     |
+---------------------------------------------------------+
```

### Example: Environment Variables

| Name             | Value                         | Environment                |
| ----             | -----                         | -----------                |
ARM_IAC_BACKEND_CN | tfstate-azure-mgt-iac-core    | Azure-PlatformLandingZone  |
ARM_IAC_BACKEND_CN | tfstate-azure-mgt-platformlz  | Azure-PlatformLandingZone  |
ARM_IAC_BACKEND_CN | tfstate-azure-app             | Azure-Workload-App01       |

## Considerations

- One storage account per environment tier (platform, workload) instead of a single global one.
