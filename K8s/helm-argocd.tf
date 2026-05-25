# 1. Create the ArgoCD Namespace
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
  depends_on = [azurerm_kubernetes_cluster.aks]
}

# 2. Automated Repository Credentials
resource "kubernetes_secret_v1" "vhg_repo_creds" {
  metadata {
    name      = "vhg-repo-creds"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = "https://dev.azure.com/navikenz/DevOps%20POCs/_git/DevOps%20POCs"
    password = var.azure_devops_pat
  }

  depends_on = [kubernetes_namespace_v1.argocd]
}

# 3. Install Argo CD
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  version    = "7.3.11"

  values = [
    <<-EOF
    configs:
      params:
        server.insecure: true
    server:
      extraArgs:
        - --rootpath=/argocd
        - --basehref=/argocd
      ingress:
        enabled: true
        ingressClassName: "nginx"
        annotations:
          nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
          nginx.ingress.kubernetes.io/ssl-redirect: "false"
          nginx.ingress.kubernetes.io/use-regex: "true"
        # Forces the ingress rule to match any incoming host name on /argocd
        hosts:
          - "*"
        paths:
          - /argocd(/|$)(.*)
    EOF
  ]

  depends_on = [
    kubernetes_secret_v1.vhg_repo_creds,
    helm_release.ingress_nginx
  ]
}

# 4. The ArgoCD Application
resource "terraform_data" "adopt_existing_argocd_bootstrap_objects" {
  provisioner "local-exec" {
    command = <<-EOT
      if kubectl get application vhg-app -n argocd >/dev/null 2>&1; then
        kubectl label application vhg-app -n argocd app.kubernetes.io/managed-by=Helm --overwrite
        kubectl annotate application vhg-app -n argocd meta.helm.sh/release-name=vhg-app meta.helm.sh/release-namespace=argocd --overwrite
      fi
      if kubectl get ingress argocd-server-ingress -n argocd >/dev/null 2>&1; then
        kubectl label ingress argocd-server-ingress -n argocd app.kubernetes.io/managed-by=Helm --overwrite
        kubectl annotate ingress argocd-server-ingress -n argocd meta.helm.sh/release-name=vhg-app meta.helm.sh/release-namespace=argocd --overwrite
      fi
    EOT
  }

  depends_on = [helm_release.argocd]
}

resource "helm_release" "vhg_app_gitops" {
  name                       = "vhg-app"
  chart                      = "${path.module}/argocd-app-chart"
  namespace                  = kubernetes_namespace_v1.argocd.metadata[0].name
  disable_openapi_validation = true
  replace                    = true
  timeout                    = 300
  wait                       = true

  values = [
    <<-EOF
    repoURL: "https://dev.azure.com/navikenz/DevOps%20POCs/_git/DevOps%20POCs"
    targetRevision: "genai"
    path: "vhg-chart"
    destinationNamespace: "vhg-1"
    EOF
  ]

  depends_on = [
    terraform_data.adopt_existing_argocd_bootstrap_objects,
    helm_release.ingress_nginx
  ]
}