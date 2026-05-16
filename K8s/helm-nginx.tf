resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  # 15 minutes to allow Azure to provision the Load Balancer hardware
  timeout = 900
  wait    = true

  # Ensure the cluster and permissions are ready before installing
  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_role_assignment.aks_network_contributor,
    azurerm_public_ip.ingress_ip
  ]

  values = [
    <<-EOF
    controller:
      service:
        loadBalancerIP: "${azurerm_public_ip.ingress_ip.ip_address}"
        externalTrafficPolicy: Local
        annotations:
          service.beta.kubernetes.io/azure-load-balancer-resource-group: "${data.azurerm_resource_group.existing_rg.name}"
    EOF
  ]
}