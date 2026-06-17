data "azurerm_resource_group" "existing_rg" {
  name = var.resource_group_name
}

# Static Public IP for Nginx Load Balancer Routing
resource "azurerm_public_ip" "ingress_ip" {
  name                = "vhg-ingress-ip"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "vhg-garden-dharshan"
}

# Managed Kubernetes Service (AKS) Pool Instance
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "vhg-aks"
  location            = var.location
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

  tags = var.common_tags

  provisioner "local-exec" {
    command = "sleep 30 && az aks get-credentials --resource-group ${self.resource_group_name} --name ${self.name} --overwrite-existing"
  }
}

# Network Contributor Role Mapping for System Identity
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = data.azurerm_resource_group.existing_rg.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# PostgreSQL Database Flexible Instance Storage
resource "azurerm_postgresql_flexible_server" "db" {
  name                   = "vhg-db-can-final-v1"
  resource_group_name    = data.azurerm_resource_group.existing_rg.name
  location               = var.location
  administrator_login    = "vhgadmin"
  administrator_password = var.db_password
  version                = "13"
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  tags                   = var.common_tags

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