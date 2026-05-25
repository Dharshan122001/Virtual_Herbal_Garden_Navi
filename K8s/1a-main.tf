terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "existing_rg" {
  name = "Darshan.k_lean_rg"
}

locals {
  location = "canadacentral"
  common_tags = {
    owner   = "dharshan.k@navikenz.com"
    project = "vhg-aks"
  }
}

# ✅ AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "vhg-aks"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  dns_prefix          = "vhg"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags

  provisioner "local-exec" {
    command = "sleep 30 && az aks get-credentials --resource-group ${self.resource_group_name} --name ${self.name} --overwrite-existing"
  }
}

# ✅ AUTOMATION: Assign Network Contributor role to AKS Managed Identity
# This removes the need for manual CLI commands
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = data.azurerm_resource_group.existing_rg.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# ✅ PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "vhg-db-can-final-v1" # Fresh unique name
  resource_group_name    = data.azurerm_resource_group.existing_rg.name
  location               = local.location
  administrator_login    = "vhgadmin"
  administrator_password = var.db_password
  version                = "13"
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  tags                   = local.common_tags

  lifecycle {
    ignore_changes = [zone]
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name             = "allow-azure"
  server_id        = azurerm_postgresql_flexible_server.db.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}