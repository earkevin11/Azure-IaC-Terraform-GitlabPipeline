resource "azurerm_subscription_policy_assignment" "allowed_resources" {
  name                 = "allowed-resources-policy"
  subscription_id      = data.azurerm_subscription.primary.id  # 👈 uses your existing data source
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a08ec900-254a-4555-9bf5-e42af04b5c5c"
  display_name         = "TEST: Allowed Resource Types V2"

  parameters = jsonencode({
    listOfResourceTypesAllowed = {
      value = [
        # Azure App Service
        "Microsoft.Web/sites",
        "Microsoft.Web/serverFarms",
        "Microsoft.Web/staticSites",

        # Azure Application Insights
        "Microsoft.Insights/components",

        # Azure Backup
        "Microsoft.RecoveryServices/vaults",
        "Microsoft.RecoveryServices/vaults/backupPolicies",

        # Azure Disk Encryption
        "Microsoft.Compute/diskEncryptionSets",

        # Azure Event Hubs
        "Microsoft.EventHub/namespaces",
        "Microsoft.EventHub/namespaces/eventhubs",

        # Azure File Sync
        "Microsoft.StorageSync/storageSyncServices",

        # Azure Key Vault
        "Microsoft.KeyVault/vaults",

        # Azure Load Balancer (Standard)
        "Microsoft.Network/loadBalancers",

        # Azure Load Testing
        "Microsoft.LoadTestService/loadTests",

        # Azure Log Analytics
        "Microsoft.OperationalInsights/workspaces",

        # Azure Managed Disks
        "Microsoft.Compute/disks",

        # Azure Managed Identity
        "Microsoft.ManagedIdentity/userAssignedIdentities",

        # Azure Monitor
        "Microsoft.Insights/actionGroups",
        "Microsoft.Insights/metricAlerts",
        "Microsoft.Insights/scheduledQueryRules",

        # Azure Notification Hubs
        "Microsoft.NotificationHubs/namespaces",
        "Microsoft.NotificationHubs/namespaces/notificationHubs",

        # Azure NSG
        "Microsoft.Network/networkSecurityGroups",

        # Azure Policy
        "Microsoft.Authorization/policyAssignments",
        "Microsoft.Authorization/policyDefinitions",
        "Microsoft.Authorization/policySetDefinitions",

        # Azure Private Link
        "Microsoft.Network/privateEndpoints",
        "Microsoft.Network/privateLinkServices",
        "Microsoft.Network/privateDnsZones",

        # Azure Purview
        "Microsoft.Purview/accounts",

        # Azure Service Bus
        "Microsoft.ServiceBus/namespaces",
        "Microsoft.ServiceBus/namespaces/queues",
        "Microsoft.ServiceBus/namespaces/topics",

        # Azure Update Manager
        "Microsoft.Maintenance/maintenanceConfigurations",
        "Microsoft.Maintenance/configurationAssignments",

        # Azure Virtual Network
        "Microsoft.Network/virtualNetworks",
        "Microsoft.Network/virtualNetworks/subnets",
        "Microsoft.Network/networkInterfaces",
        "Microsoft.Network/publicIPAddresses",

        # Virtual Machines
        "Microsoft.Compute/virtualMachines",
        "Microsoft.Compute/virtualMachineScaleSets",

        # Azure Cache for Redis
        "Microsoft.Cache/redis",

        # Azure Managed Redis
        "Microsoft.Cache/redisEnterprise",

        # Azure Storage Accounts
        "Microsoft.Storage/storageAccounts",

        # Azure Snapshots
        "Microsoft.Compute/snapshots",

        # Azure SQL server
        "Microsoft.Sql/servers"
      ]
    }
  })
}