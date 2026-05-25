# K8s/ingress-tools.tf

# -----------------------------------------------------------------
# 1. CROSS-NAMESPACE SERVICE POINTERS (EXTERNAL NAME BRIDGES)
# -----------------------------------------------------------------

resource "kubernetes_service_v1" "argo_bridge" {
  metadata {
    name      = "argo-bridge"
    namespace = "vhg-1"
  }
  spec {
    type          = "ExternalName"
    external_name = "argocd-server.argocd.svc.cluster.local"
    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_service_v1" "prometheus_bridge" {
  metadata {
    name      = "prometheus-bridge"
    namespace = "vhg-1"
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
    namespace = "vhg-1"
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


# -----------------------------------------------------------------
# 2. UNIFIED INGRESS DEVOPS TOOLS ROUTING
# -----------------------------------------------------------------

resource "kubernetes_ingress_v1" "devops_tools_ingress" {
  metadata {
    name      = "vhg-devops-tools-ingress"
    namespace = "vhg-1"
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
        # 1. Argo CD Mapping
        path {
          path      = "/argocd(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service_v1.argo_bridge.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }

        # 2. Prometheus Mapping
        path {
          path      = "/prometheus(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service_v1.prometheus_bridge.metadata[0].name
              port {
                number = 9090
              }
            }
          }
        }

        # 3. Grafana Mapping
        path {
          path      = "/grafana(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service_v1.grafana_bridge.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.ingress_nginx,
    helm_release.argocd,
    helm_release.monitoring
  ]
}