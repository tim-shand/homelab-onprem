// Reference to the extension 'alias' name in 'bicepconfig.json' file.
extension microsoftGraphV1

// Target Scope to the tenant as we are working with Entra ID.
targetScope = 'tenant'

// Declare Parameters (using params file).
param groupName string
param appName string
param appDisplayName string
param appDesc string

// Note: Not fully support yet.
//param appCredPrefix string
// Date usage with 'utcNow()' is not yet supported in 'parameter' files.
//param appCredStart string = utcNow('yyyy-MM-ddThh:mm:ss')
//param appCredEnd string = dateTimeAdd(appCredStart, 'P1Y') // Plus 1 year.

// Create Resources.
resource clientApp 'Microsoft.Graph/applications@v1.0' = {
  uniqueName: appName
  displayName: appDisplayName
  description: appDesc
  signInAudience: 'AzureADMyOrg'
  // passwordCredentials: [
  //   {
  //     displayName: appCredPrefix
  //     startDateTime: appCredStart
  //     endDateTime: appCredEnd
  //   }
  // ]
}

resource clientSp 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: clientApp.appId
}

resource group 'Microsoft.Graph/groups@v1.0' = {
  displayName: groupName
  mailEnabled: false
  mailNickname: groupName
  securityEnabled: true
  uniqueName: groupName
  members: [
    clientSp.id
  ]
}

// Out the values from created resources. 
output clientApp_appId string = clientApp.appId

// Note: Not fully support yet.
// output clientAppSecret_Name array = clientApp.passwordCredentials
// output clientAppSecret_Value array = clientApp.passwordCredentials
