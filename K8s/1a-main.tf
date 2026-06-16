terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
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

# ✅ AKS Cluster Configuration
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
}

# ✅ Dynamically wire Kubernetes provider straight into the new cluster
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}

# ✅ Dynamically wire Helm provider straight into the new cluster
provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  }
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = data.azurerm_resource_group.existing_rg.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# ✅ PostgreSQL Flexible Server Setup
resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "vhg-db-can-final-v1"
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