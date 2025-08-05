param appServicePlanName string = 'onxdel-plan-starter'

param location string =  resourceGroup().location

@description('The kind of App Service Plan. For Linux, use "Linux" or "ElasticPremium". For Windows, use "Windows".')
param appServiceKind string = 'Linux'

@description('The SKU name for the App Service Plan. For example, "F1" for Free, "B1" for Basic, etc.')
@allowed(['F1', 'B1', 'S1', 'P1v2', 'P2v2', 'P3v2'])
param skuName string = 'F1'

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
    tier: 'Free'
  }
  kind: 'app,linux'
  properties:{
    reserved: true
  }
}

resource appServiceApp 'Microsoft.Web/sites@2024-04-01' = {
  name: 'onax-test-launch-1'
  location: location
  kind: appServiceKind
  properties: {
    serverFarmId: appServicePlan.id
    reserved: true
    httpsOnly: true
  }
}

param functionAppServicePlanName string = 'onaxgenai-app-svc'

@allowed(['FC1','Y1'])
param functionAppSkuName string = 'FC1'

param storageAccountName string = 'onaxgenaist${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: 'Canada Central'
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource deploymentContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'deployments'
  properties: {
    publicAccess: 'None'
  }
}

resource functionAppContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'function-app-data'
  properties: {
    publicAccess: 'None'
  }
}

resource functionAppServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: functionAppServicePlanName
  location: 'Canada Central'
  sku: {
    name: functionAppSkuName
    tier: 'Dynamic'
  }
  kind: 'app,linux'
  properties:{
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: 'onaxgenai'
  location: 'Canada Central'
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: functionAppServicePlan.id
    httpsOnly: true
    reserved: true
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: 'https://${storageAccount.name}.blob.${environment().suffixes.storage}/${deploymentContainer.name}'
          authentication: {
            type: 'StorageAccountConnectionString'
            storageAccountConnectionStringName: 'AzureWebJobsStorage'
          }
        }
      }
      runtime: {
        name: 'python'
        version: '3.12'
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 200
        instanceMemoryMB: 2048
      }
    }
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'BLOB_STORAGE_CONNECTION_STRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'BLOB_CONTAINER_NAME'
          value: functionAppContainer.name
        }
      ]
    }
  }
}
