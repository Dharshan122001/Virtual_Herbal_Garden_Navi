output "aks_host" {
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  description = "The public API server endpoint host address for the AKS cluster."
}

output "aks_client_certificate" {
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
  description = "Base64 encoded client certificate data cluster parameter."
}

output "aks_client_key" {
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
  description = "Base64 encoded private client certificate key data."
}

output "aks_cluster_ca_certificate" {
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  description = "Base64 encoded authority root certificate data layer."
}

output "db_fqdn" {
  value       = azurerm_postgresql_flexible_server.db.fqdn
  description = "The fully qualified domain host connection path name of the database."
}

output "db_user" {
  value       = azurerm_postgresql_flexible_server.db.administrator_login
  description = "The master username string credential for server access."
}

output "ingress_ip" {
  value       = azurerm_public_ip.ingress_ip.ip_address
  description = "The static public IP assigned to the entry load balancer routing points."
}