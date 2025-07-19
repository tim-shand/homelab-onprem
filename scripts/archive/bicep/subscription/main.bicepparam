using 'main.bicep'

param rgName = 'tjs-sysautomation-prd-rg'
param location = 'australiaeast'
param tags = {
  createdby: 'bicep'
  environment: 'prd'
  project: 'automation'
}
param staName = 'tjssysautomationsa1'
param stbName = 'tjs-sysautomation-bl'
param stcName = 'tjs-terraform-state'
