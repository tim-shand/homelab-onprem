# Deployment: Azure IaC Backends

This deployment uses a small Terraform module to create Azure resources to be used for remote Terraform states. 

This allows for centralized storage of workload and platform project state files. This can be helpful when utilizing a monolithic style repository, as all project state files can be managed from the one storage account. Permissions can be assigned as RBAC roles to each projects container. 

## Requirements

- Targets: Azure IaC Subscription, Github Repo Environments.
- Requires: Azure Service Principal: `Application.ReadWrite.All`, `Directory.ReadWrite.All`.
- Requires: Github: OAUTH Token added to repo secrets.

## Actions

- Creates containers per project in a storage account, located in the IaC Azure subscription.
- Adds the `ARM_IAC_BACKEND_CN` variable to the specified Github repo environment.
- Adds a federated credential (OIDC) to the service principal used for IaC deployments.

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
