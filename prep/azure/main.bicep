// =========== main.bicep =========== //

targetScope = 'subscription'

// Declare Parameters (using params file).
// Params: Resource Groups
param rgName string
param location string
param tags object
// Params: Storage 
param staName string
param stbName string
param stcName string

// Create: Resource Group 
resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  //scope: subscription()
  name: rgName
  location: location
  tags: tags
}

// Create: Storage Account and Key Vault
module resources 'resources.bicep' = {
  scope: resourceGroup
  name: 'deploy_resources'
  params: {
    staName: staName
    stbName: stbName
    stcName: stcName
    location: location
    tags: tags
  }
}
