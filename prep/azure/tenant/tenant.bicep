// Reference to the extension 'alias' name in 'bicepconfig.json' file.
extension microsoftGraphV1

// Target Scope to the tenant as we are working with Entra ID.
targetScope = 'tenant'

// Declare Parameters (using params file)

param groupName string
param appRegName string
param appRegDisplayName string
param appRegDesc string
param appRegName2 string
param appRegDisplayName2 string
param appRegDesc2 string
// param appRegCredPrefix string
// param appRegCredStart string = utcNow('u')
// param zBaseTime string = utcNow('u')
// var appRegCredEnd = dateTimeAdd(appRegCredStart, 'P1Y')

// Create App Registration in Entra ID.
resource appReg 'Microsoft.Graph/applications@v1.0' = {
  uniqueName: appRegName
  displayName: appRegDisplayName
  description: appRegDesc
  signInAudience: 'AzureADMyOrg'
}

resource appReg2 'Microsoft.Graph/applications@v1.0' = {
  uniqueName: appRegName2
  displayName: appRegDisplayName2
  description: appRegDesc2
  signInAudience: 'AzureADMyOrg'
}

// Create Service Principal for App Registration.
resource appRegSP 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: appReg.appId
}

resource appRegSP2 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: appReg2.appId
}

// Create group in Entra ID for automation accounts.
// Add Service Principal to Entra ID group as a member.
resource group 'Microsoft.Graph/groups@v1.0' = {
  displayName: groupName
  mailEnabled: false
  mailNickname: groupName
  securityEnabled: true
  uniqueName: groupName
  members: [
    appRegSP.id
    appRegSP2.id
  ]
}

// Output the values from created resources. 
output clientApp_appId string = appRegSP.appId
output clientApp_appId2 string = appRegSP2.appId
