resource "helm_release" "vhg_app" {
  name      = "vhg-app"
  chart     = "../vhg-chart"
  namespace = "vhg-1"

  create_namespace = true

  # ARCHITECT TIP: Pass the DB host directly from Terraform outputs to Helm if needed
  values = [
    file("../vhg-chart/values.yaml")
  ]

  wait          = true
  timeout       = 600
  force_update  = true
  recreate_pods = true

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    helm_release.ingress_nginx,
    azurerm_postgresql_flexible_server.db
  ]
}