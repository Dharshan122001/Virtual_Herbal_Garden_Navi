resource "helm_release" "monitoring" {
  name             = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  timeout = 1200 # 20 minutes to comfortably avoid OpenAPI download connection drops
  wait    = true

  values = [
    <<-EOF
    grafana:
      enabled: true
      service:
        type: ClusterIP
      grafana.ini:
        server:
          root_url: "%(protocol)s://%(domain)s:%(http_port)s/grafana/"
          serve_from_sub_path: true
      ingress:
        enabled: false # Disabled: Routing centralized in ingress-tools.tf

    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false
        podMonitorSelectorNilUsesHelmValues: false
        podMonitorSelector: {}
        serviceMonitorSelector: {}
        routePrefix: /prometheus
        externalUrl: /prometheus
      ingress:
        enabled: false # Disabled: Routing centralized in ingress-tools.tf

    kubeStateMetrics:
      enabled: true
    nodeExporter:
      enabled: true
    alertmanager:
      enabled: false
    EOF
  ]

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    helm_release.ingress_nginx
  ]
}