provider "kubernetes" {
  host                   = module.azure_infra.aks_host
  client_certificate     = base64decode(module.azure_infra.aks_client_certificate)
  client_key             = base64decode(module.azure_infra.aks_client_key)
  cluster_ca_certificate = base64decode(module.azure_infra.aks_cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.azure_infra.aks_host
    client_certificate     = base64decode(module.azure_infra.aks_client_certificate)
    client_key             = base64decode(module.azure_infra.aks_client_key)
    cluster_ca_certificate = base64decode(module.azure_infra.aks_cluster_ca_certificate)
  }
}