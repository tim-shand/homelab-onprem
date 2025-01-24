using 'tenant.bicep'

// Entra ID: Group
param groupName = toLower('sys-role-automation')

// Entra ID: App Registration
param appName = toLower('sys-automation-terraform')
param appDisplayName = 'sys-automation-terraform'
param appDesc = 'System: Automation (Terraform)'
