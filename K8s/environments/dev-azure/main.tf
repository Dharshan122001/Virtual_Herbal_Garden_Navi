terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm    = { source = "hashicorp/azurerm", version = "~> 4.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.0" }
    helm       = { source = "hashicorp/helm", version = "~> 2.0" }
  }
}

provider "azurerm" {
  features {}
}

# 🏗️ TRIGGER CORE REUSABLE BLUEPRINT MODULE
module "azure_infra" {
  source              = "../../modules/azure_infra"
  resource_group_name = "Darshan.k_lean_rg"
  location            = "canadacentral"
  db_password         = var.db_password
  common_tags         = { owner = "dharshan.k@navikenz.com", project = "vhg-aks" }
}

# ====================================================================================
# APPLICATION ORCHESTRATION LAYER (FED BY BLUEPRINT OUTPUT VARIABLES)
# ====================================================================================

resource "kubernetes_namespace_v1" "vhg_namespace" {
  metadata { name = "vhg-1" }
}

resource "kubernetes_secret_v1" "vhg_db_config" {
  metadata {
    name      = "vhg-db-config"
    namespace = kubernetes_namespace_v1.vhg_namespace.metadata[0].name
  }
  data = {
    POSTGRES_HOST     = module.azure_infra.db_fqdn
    POSTGRES_USER     = module.azure_infra.db_user
    POSTGRES_PASSWORD = var.db_password
    POSTGRES_PORT     = "5432"
    POSTGRES_DB       = "vhg_prod"
  }
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  timeout          = 1500
  wait             = true

  values = [
    <<-EOF
    controller:
      service:
        loadBalancerIP: "${module.azure_infra.ingress_ip}"
        externalTrafficPolicy: Local
        annotations:
          service.beta.kubernetes.io/azure-load-balancer-resource-group: "Darshan.k_lean_rg"
    EOF
  ]
}

resource "helm_release" "otel_collector" {
  name             = "otel-collector"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  namespace        = "monitoring"
  create_namespace = true
  timeout          = 600

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
            receivers: ["otlp"]
            processors: ["batch"]
            exporters: ["debug"]
    EOF
  ]
}

resource "helm_release" "monitoring" {
  name             = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  timeout          = 1200
  wait             = true
  depends_on       = [helm_release.ingress_nginx]

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
        enabled: false

    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false
        podMonitorSelectorNilUsesHelmValues: false
        podMonitorSelector: {}
        serviceMonitorSelector: {}
        routePrefix: /prometheus
        externalUrl: /prometheus
      ingress:
        enabled: false

    kubeStateMetrics:
      enabled: true
    nodeExporter:
      enabled: true
      
    alertmanager:
      enabled: true
      alertmanagerSpec:
        routePrefix: /alertmanager
        externalUrl: "http://${module.azure_infra.ingress_ip}/alertmanager/"
      ingress:
        enabled: false
    EOF
  ]
}

# ====================================================================================
# CROSS-NAMESPACE SERVICE POINTERS
# ====================================================================================

resource "kubernetes_service_v1" "prometheus_bridge" {
  metadata {
    name      = "prometheus-bridge"
    namespace = kubernetes_namespace_v1.vhg_namespace.metadata[0].name
  }
  spec {
    type          = "ExternalName"
    external_name = "monitoring-kube-prometheus-prometheus.monitoring.svc.cluster.local"
    port {
      port        = 9090
      target_port = 9090
    }
  }
}

resource "kubernetes_service_v1" "grafana_bridge" {
  metadata {
    name      = "grafana-bridge"
    namespace = kubernetes_namespace_v1.vhg_namespace.metadata[0].name
  }
  spec {
    type          = "ExternalName"
    external_name = "monitoring-grafana.monitoring.svc.cluster.local"
    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_service_v1" "alertmanager_bridge" {
  metadata {
    name      = "alertmanager-bridge"
    namespace = kubernetes_namespace_v1.vhg_namespace.metadata[0].name
  }
  spec {
    type          = "ExternalName"
    external_name = "monitoring-kube-prometheus-alertmanager.monitoring.svc.cluster.local"
    port {
      port        = 9093
      target_port = 9093
    }
  }
}

# ====================================================================================
# UNIFIED INGRESS DEVOPS ROUTING GATEWAY
# ====================================================================================

resource "kubernetes_ingress_v1" "devops_tools_ingress" {
  metadata {
    name      = "vhg-devops-tools-ingress"
    namespace = kubernetes_namespace_v1.vhg_namespace.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"              = "nginx"
      "nginx.ingress.kubernetes.io/use-regex"    = "true"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      http {
        path {
          path      = "/prometheus(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service_v1.prometheus_bridge.metadata[0].name
              port { number = 9090 }
            }
          }
        }

        path {
          path      = "/grafana(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service_v1.grafana_bridge.metadata[0].name
              port { number = 80 }
            }
          }
        }

        path {
          path      = "/alertmanager(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service_v1.alertmanager_bridge.metadata[0].name
              port { number = 9093 }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.ingress_nginx,
    helm_release.monitoring
  ]
}