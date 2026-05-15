# 1. Create the Application Namespace
resource "kubernetes_namespace_v1" "vhg_namespace" {
  metadata {
    name = "vhg-1"
  }
  depends_on = [azurerm_kubernetes_cluster.aks]
}

# 2. Database Connectivity Secret
# Argo CD will deploy the pods, but they will pull DB details from this secret
resource "kubernetes_secret_v1" "vhg_db_config" {
  metadata {
    name      = "vhg-db-config"
    namespace = kubernetes_namespace_v1.vhg_namespace.metadata[0].name
  }

  data = {
    POSTGRES_HOST     = azurerm_postgresql_flexible_server.db.fqdn
    POSTGRES_USER     = azurerm_postgresql_flexible_server.db.administrator_login
    POSTGRES_PASSWORD = var.db_password
    POSTGRES_PORT     = "5432"
    POSTGRES_DB       = "neondb"
  }

  depends_on = [
    azurerm_postgresql_flexible_server.db,
    kubernetes_namespace_v1.vhg_namespace
  ]
}