resource "helm_release" "otel_collector" {
  name             = "otel-collector"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  namespace        = "monitoring"
  create_namespace = true

  timeout = 600

  values = [
    <<-EOF
mode: deployment

image:
  repository: otel/opentelemetry-collector-k8s

config:
  receivers:
    otlp:
      protocols:
        grpc: {}
        http: {}

  processors:
    batch: {}

  exporters:
    debug: {}

  service:
    pipelines:
      traces:
        receivers:
          - otlp
        processors:
          - batch
        exporters:
          - debug
EOF
  ]
}