output "db_host" {
  value = azurerm_postgresql_flexible_server.db.fqdn
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "ingress_public_ip" {
  value = azurerm_public_ip.ingress_ip.ip_address
}

output "access_urls" {
  value = {
    application = "http://${azurerm_public_ip.ingress_ip.ip_address}/"
    argocd      = "http://${azurerm_public_ip.ingress_ip.ip_address}/argocd/"
    prometheus  = "http://${azurerm_public_ip.ingress_ip.ip_address}/prometheus/"
    grafana     = "http://${azurerm_public_ip.ingress_ip.ip_address}/grafana/"
  }
  description = "Access endpoints for all services exposed under the single dynamic Ingress IP."
}