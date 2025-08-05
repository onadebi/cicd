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
    siteConfig: {
      linuxFxVersion: 'Python|3.12'
    }
  }
  

}
