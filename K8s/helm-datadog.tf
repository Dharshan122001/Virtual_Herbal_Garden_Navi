resource "helm_release" "datadog" {
  name             = "datadog"
  repository       = "https://helm.datadoghq.com"
  chart            = "datadog"
  namespace        = "datadog"
  create_namespace = true

  timeout = 900
  wait    = true

  values = [
    <<-EOF
    datadog:
      apiKey: "${var.datadog_api_key}"
      site: "${var.datadog_site}"
      apm:
        portEnabled: true
      logs:
         enabled: true
      tags:
        - "env:aks"
        - "service_namespace:virtual-herbal-garden"
        - "project:vhg-aks"
      logs:
        enabled: true
        containerCollectAll: true
      otlp:
        receiver:
          protocols:
            grpc:
              enabled: true
            http:
              enabled: true
        logs:
          enabled: false
    clusterAgent:
      enabled: true
    kubeStateMetricsCore:
      enabled: true
    EOF
  ]

  depends_on = [azurerm_kubernetes_cluster.aks]
}
