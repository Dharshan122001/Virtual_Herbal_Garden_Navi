data "kubernetes_secret_v1" "grafana_secret" {
  metadata {
    name      = "monitoring-grafana"
    namespace = "monitoring"
  }
  depends_on = [helm_release.monitoring]
}

output "db_host" {
  value = module.azure_infra.db_fqdn
}

output "cluster_name" {
  value = "vhg-aks"
}

output "ingress_public_ip" {
  value = module.azure_infra.ingress_ip
}

output "access_urls" {
  value = {
    application = "http://${module.azure_infra.ingress_ip}/"
    prometheus  = "http://${module.azure_infra.ingress_ip}/prometheus/"
    grafana     = "http://${module.azure_infra.ingress_ip}/grafana/"
  }
}

output "decrypted_tool_passwords" {
  value = {
    username         = "admin"
    grafana_password = data.kubernetes_secret_v1.grafana_secret.data["admin-password"]
  }
  sensitive = true
}