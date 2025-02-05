using 'tenant.bicep'

// Entra ID: Group
param groupName = toLower('sys-role-automation')

// Entra ID: App Registration
param appRegName = toLower('sys-automation-terraform')
param appRegDisplayName = 'sys-automation-terraform'
param appRegDesc = 'System: Automation (Terraform)'
// param appRegCredPrefix = '${appRegName}' // Not supported in Bicep.
//param tags = ['project','sys-automation'] // Not required.
