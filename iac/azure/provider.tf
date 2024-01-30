provider "azurerm" {
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.this.kube_admin_config.0.host
  username               = azurerm_kubernetes_cluster.this.kube_admin_config.0.username
  password               = azurerm_kubernetes_cluster.this.kube_admin_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.this.kube_admin_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.this.kube_admin_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.this.kube_admin_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
  host                   = azurerm_kubernetes_cluster.this.kube_admin_config.0.host
  username               = azurerm_kubernetes_cluster.this.kube_admin_config.0.username
  password               = azurerm_kubernetes_cluster.this.kube_admin_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.this.kube_admin_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.this.kube_admin_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.this.kube_admin_config.0.cluster_ca_certificate)
  }
}

