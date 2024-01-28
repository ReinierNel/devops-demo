terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.77.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.47.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.11.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.1"
    }
  }
  backend "azurerm" {
    resource_group_name  = "manual"
    storage_account_name = "rnrtfstate"
    container_name       = "tfstate"
    key                  = "devops-demo.tfstate"
    tenant_id            = "e9a49ca6-aef5-4fe3-80b8-87b7406d5bf0"
    subscription_id      = "42fac477-e696-455c-af82-524aeaad005d"
  }
}
