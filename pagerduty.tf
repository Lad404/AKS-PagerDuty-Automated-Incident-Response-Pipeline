# --- 1. TERRAFORM & PROVIDER CONFIGURATION ---
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  # This prevents Terraform from trying to register all 200+ Azure providers
  resource_provider_registrations = "none"
}

# --- 2. RESOURCE GROUP ---
resource "azurerm_resource_group" "devops_rg" {
  name     = "DevOps-Project-RG"
  location = "Central India"
}

# --- 3. LOG ANALYTICS WORKSPACE ---
resource "azurerm_log_analytics_workspace" "aks_logs" {
  name                = "aks-monitoring-workspace"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
  sku                 = "PerGB2018"
}

# --- 4. AKS CLUSTER ---
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "devops-aks-cluster"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
  dns_prefix          = "sumit-aks-devops" 
  sku_tier            = "Free"

  default_node_pool {
    name       = "default"
    node_count = 1 
    vm_size    = "Standard_B2s_v2" 
  }

  identity {
    type = "SystemAssigned"
  }

  # This connects AKS to Log Analytics so we can query pod status
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs.id
  }
}

# --- 5. PAGERDUTY ACTION GROUP ---
resource "azurerm_monitor_action_group" "pagerduty_action" {
  name                = "NotifyPagerDutyAKS"
  resource_group_name = azurerm_resource_group.devops_rg.name
  short_name          = "pd-aks"

  webhook_receiver {
    name                    = "pagerduty-webhook"
    # Using your PagerDuty Integration URL
    service_uri             = "https://events.pagerduty.com/integration/d8b8a3c597514a07d0fafb039076d781/enqueue"
    use_common_alert_schema = true
  }
}

# --- 6. MONITORING ALERT RULE ---
resource "azurerm_monitor_scheduled_query_rules_alert" "pod_down_alert" {
  name                = "AKS-Pod-Down-Alert"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name

  data_source_id = azurerm_log_analytics_workspace.aks_logs.id
  description    = "Alert when a pod is not in Running state"
  enabled        = true

  # KQL Query: Looks for any pod that isn't 'Running'
  query = <<-KQL
    KubePodInventory
    | where PodStatus != "Running"
    | summarize AggregatedValue = count() by bin(TimeGenerated, 5m), Name, Namespace
  KQL

  severity    = 1
  frequency   = 5 
  time_window = 5

  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  action {
    action_group = [azurerm_monitor_action_group.pagerduty_action.id]
  }
}