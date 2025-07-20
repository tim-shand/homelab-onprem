using 'tenant.bicep'

// Entra ID: Group
param groupName = toLower('sys-role-automation')

// Entra ID: App Registration
param appRegName = toLower('sys-automation-tf')
param appRegDisplayName = 'sys-automation-tf'
param appRegDesc = 'System: Automation (Terraform)'
// param appRegCredPrefix = '${appRegName}' // Not supported in Bicep.
//param tags = ['project','sys-automation'] // Not required.
param appRegName2 = toLower('sys-automation-gha')
param appRegDisplayName2 = 'sys-automation-gha'
param appRegDesc2 = 'System: Automation (Github Actions)'
