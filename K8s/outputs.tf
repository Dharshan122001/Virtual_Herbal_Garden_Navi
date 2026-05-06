output "db_host" {
  value = azurerm_postgresql_flexible_server.db.fqdn
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "app_ip" {
  value = "Run: kubectl get ingress -n vhg-1"
}