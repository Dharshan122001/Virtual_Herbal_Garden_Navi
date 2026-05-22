resource "helm_release" "monitoring" {
  name             = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  timeout = 900
  wait    = true

  values = [
    <<-EOF
    grafana:
      enabled: true
      service:
        type: ClusterIP
      ingress:
        enabled: false
    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false
        podMonitorSelectorNilUsesHelmValues: false
        podMonitorSelector: {}
        serviceMonitorSelector: {}
    kubeStateMetrics:
      enabled: true
    nodeExporter:
      enabled: true
    alertmanager:
      enabled: false
    EOF
  ]

  depends_on = [azurerm_kubernetes_cluster.aks]
}
