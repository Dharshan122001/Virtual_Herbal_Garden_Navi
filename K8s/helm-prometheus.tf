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
      # Tells Grafana's engine to rewrite asset URLs for subpath proxying
      grafana.ini:
        server:
          root_url: "%(protocol)s://%(domain)s:%(http_port)s/grafana/"
          serve_from_sub_path: true
      ingress:
        enabled: false
        ingressClassName: "nginx"
        annotations:
          nginx.ingress.kubernetes.io/ssl-redirect: "false"
        path: /grafana

    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false
        podMonitorSelectorNilUsesHelmValues: false
        podMonitorSelector: {}
        serviceMonitorSelector: {}
        # Forces Prometheus engine to host assets relative to /prometheus
        routePrefix: /prometheus
        externalUrl: /prometheus
      ingress:
        enabled: false
        ingressClassName: "nginx"
        annotations:
          nginx.ingress.kubernetes.io/ssl-redirect: "false"
        paths:
          - /prometheus

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