resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  timeout = 900 # 15 minutes for Azure LoadBalancer provisioning
  wait    = true

  # Ensure permissions and IP exist before starting
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