resource "kubernetes_namespace_v1" "datadog" {
  metadata {
    name = "datadog"
  }
  depends_on = [azurerm_kubernetes_cluster.aks]
}

resource "helm_release" "datadog_otel" {
  name       = "datadog-otel"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  namespace  = kubernetes_namespace_v1.datadog.metadata[0].name
  version    = "0.110.0"
  wait       = false

  set = [
    {
      name  = "fullnameOverride"
      value = "datadog-otel-opentelemetry-collector"
    },
    {
      name  = "global.cluster"
      value = "aks-vhg-cluster"
    }
  ]

  values = [
    <<-EOF
    mode: deployment
    image:
      repository: "otel/opentelemetry-collector-contrib"

    ports:
      otlp:
        enabled: true
        containerPort: 4317
        servicePort: 4317
        protocol: TCP
      otlp-http:
        enabled: true
        containerPort: 4318
        servicePort: 4318
        protocol: TCP

    config:
      receivers:
        otlp:
          protocols:
            grpc:
              endpoint: 0.0.0.0:4317
            http:
              endpoint: 0.0.0.0:4318

      processors:
        batch:
          send_batch_size: 1000
          timeout: 10s
        resource:
          attributes:
            - key: cloud.platform
              value: "azure_aks"
              action: insert
            - key: instrumentation.provider
              value: "opentelemetry"
              action: insert

      exporters:
        datadog:
          api:
            key: "${var.datadog_api_key}"
          site: "${var.datadog_site}"

      service:
        pipelines:
          traces:
            receivers: [otlp]
            processors: [resource, batch]
            exporters: [datadog]
          metrics:
            receivers: [otlp]
            processors: [resource, batch]
            exporters: [datadog]
          logs:
            receivers: [otlp]
            processors: [resource, batch]
            exporters: [datadog]
    EOF
  ]
}