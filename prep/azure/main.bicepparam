using 'main.bicep'

param rgName = 'tjs-sys-automation-rg'
param location = 'australiaeast'
param tags = {
  CreatedBy: 'Bicep'
  Environment: 'Sys'
  Project: 'Automation'
}
param staName = 'tjssysautomationsa1'
param stbName = 'tjs-sys-automation-bl'
param stcName = 'tjs-sys-terraform-state'
