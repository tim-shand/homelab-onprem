// Target Scope to the subscription as we are working with Azure ARM.
targetScope = 'resourceGroup'

// Declare Parameters (using params file).
param staName string
param stbName string
param stcName string
param location string
param tags object

// Create: Storage Account
resource newStorage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: staName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: tags
}

// Create: Storage Account > Blob Service
resource newStorageBlob 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: newStorage
  name: stbName
  properties: {
    containerDeleteRetentionPolicy: {
      allowPermanentDelete: true
      days: 5
      enabled: false
    }
  }
}

// Create: Storage Account > Blob Service > Container
resource newStorageBlobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: newStorageBlob
  name: stcName
}
