# =================================================================
# 1. KUBERNETES DYNAMIC SECRET LOOKUPS
# =================================================================

# Pulls the auto-generated initial administrative password for Argo CD
data "kubernetes_secret_v1" "argocd_initial_secret" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = "argocd"
  }
  # Ensures the lookup isn't attempted until the helm deployment finishes creating it
  depends_on = [helm_release.argocd]
}

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
    argocd      = "http://${azurerm_public_ip.ingress_ip.ip_address}/argocd/"
    prometheus  = "http://${azurerm_public_ip.ingress_ip.ip_address}/prometheus/"
    grafana     = "http://${azurerm_public_ip.ingress_ip.ip_address}/grafana/"
  }
  description = "Access endpoints for application and tools running under a single dynamic Ingress IP."
}

# Marking these sensitive hides raw string characters from CI build logs but leaves them queryable locally
output "decrypted_tool_passwords" {
  value = {
    username        = "admin"
    argocd_password = data.kubernetes_secret_v1.argocd_initial_secret.data["password"]
    grafana_password = data.kubernetes_secret_v1.grafana_secret.data["admin-password"]
  }
  sensitive   = true
  description = "Administrative login credentials for Argo CD and Grafana interfaces."
} 

output "decrypted_tool_password_show" {
  value = {
    passwords_to_show = "terraform output decrypted_tool_passwords "
  }
  
} 