// CSP451 2026F - Resource group scoped cost budget with 50 / 80 / 100 percent alerts.
// Deploy with:
//   az deployment group create --resource-group <rg> --template-file budget.bicep \
//     --parameters budgetName=budget-csp451-<team> amount=20 \
//                  contactEmails="['<your-seneca-email>']" actionGroupId=<action group resource id>

targetScope = 'resourceGroup'

@description('Name of the budget resource.')
param budgetName string

@description('Budget amount in the subscription billing currency.')
@minValue(1)
param amount int = 20

@description('Email addresses that receive the budget notifications.')
param contactEmails array

@description('Resource ID of an action group that also receives the notifications.')
param actionGroupId string = ''

@description('First day of the month in which the budget starts. Defaults to the current month.')
param startDate string = utcNow('yyyy-MM-01')

@description('Last day the budget is evaluated. Defaults to two years after the start.')
param endDate string = dateTimeAdd(utcNow('yyyy-MM-01'), 'P2Y', 'yyyy-MM-dd')

var contactGroups = empty(actionGroupId) ? [] : [ actionGroupId ]

resource budget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: budgetName
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
      endDate: endDate
    }
    notifications: {
      Actual_GreaterThan_50_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 50
        thresholdType: 'Actual'
        contactEmails: contactEmails
        contactGroups: contactGroups
        locale: 'en-us'
      }
      Actual_GreaterThan_80_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: contactEmails
        contactGroups: contactGroups
        locale: 'en-us'
      }
      Actual_GreaterThan_100_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Actual'
        contactEmails: contactEmails
        contactGroups: contactGroups
        locale: 'en-us'
      }
      Forecasted_GreaterThan_100_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: contactEmails
        contactGroups: contactGroups
        locale: 'en-us'
      }
    }
  }
}

output budgetId string = budget.id
