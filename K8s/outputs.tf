# =================================================================
# 1. KUBERNETES DYNAMIC SECRET LOOKUPS
# =================================================================

# Pulls the administrative password for the Grafana installation dashboard
data "kubernetes_secret_v1" "grafana_secret" {
  metadata {
    name      = "monitoring-grafana"
    namespace = "monitoring"
  }
  depends_on = [helm_release.monitoring]
}


# =================================================================
# 2. CENTRALIZED OUTPUT ARRAYS
# =================================================================

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
    prometheus  = "http://${azurerm_public_ip.ingress_ip.ip_address}/prometheus/"
    grafana     = "http://${azurerm_public_ip.ingress_ip.ip_address}/grafana/"
  }
  description = "Access endpoints for application and tools running under a single dynamic Ingress IP."
}

# Marking these sensitive hides raw string characters from CI build logs but leaves them queryable locally
output "decrypted_tool_passwords" {
  value = {
    username         = "admin"
    grafana_password = data.kubernetes_secret_v1.grafana_secret.data["admin-password"]
  }
  sensitive   = true
  description = "Administrative login credentials for Grafana."
}
