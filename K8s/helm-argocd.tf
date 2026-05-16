# 1. Create the ArgoCD Namespace (v1 used to remove warnings)
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

  # Updated syntax: use '=' and wrap in [ ] for a list of objects
  set = [
    {
      name  = "server.extraArgs"
      value = "{--insecure}"
    }
  ]

  depends_on = [kubernetes_secret_v1.vhg_repo_creds]
}

# 4. The ArgoCD Application (Points to your 'DataDog' branch)
resource "kubernetes_manifest" "vhg_app_gitops" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "vhg-app"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://dev.azure.com/navikenz/DevOps%20POCs/_git/DevOps%20POCs"
        targetRevision = "DataDog"
        path           = "vhg-chart"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "vhg-1"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }
  depends_on = [helm_release.argocd]
}