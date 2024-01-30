resource "azurerm_resource_group" "this" {
  name     = local.full_name
  location = lookup(local.deployment_params, local.branch_slug, local.deployment_params.default).location
  tags     = local.tags
}

resource "azurerm_dns_zone" "this" {
  name                = "${lookup(local.deployment_params, local.branch_slug, local.deployment_params.default).dns_zone_name}.${local.root_dns_zone}"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_dns_ns_record" "this" {
  name                = lookup(local.deployment_params, local.branch_slug, local.deployment_params.default).dns_zone_name
  zone_name           = local.root_dns_zone
  resource_group_name = local.root_dns_zone_resoruce_group_name
  ttl                 = 60
  records             = azurerm_dns_zone.this.name_servers
  tags                = local.tags
}

resource "azurerm_container_registry" "this" {
  name                = local.simple_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.full_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_kubernetes_cluster" "this" {
  name                      = local.full_name
  location                  = azurerm_resource_group.this.location
  resource_group_name       = azurerm_resource_group.this.name
  dns_prefix                = local.simple_name
  workload_identity_enabled = true
  oidc_issuer_enabled       = true
  node_resource_group       = "${local.full_name}-nodes"

  # enabled this as tfsec failes ci see commeted code below
  api_server_authorized_ip_ranges = lookup(local.deployment_params, local.branch_slug, local.deployment_params.default).trusted_ip_addresses

  # api_server_access_profile {
  #   authorized_ip_ranges = lookup(local.deployment_params, local.branch_slug, local.deployment_params.default).trusted_ip_addresses
  # }

  default_node_pool {
    name       = "default"
    node_count = lookup(local.deployment_params, local.branch_slug, local.deployment_params.default).default_node_pool_count
    vm_size    = lookup(local.deployment_params, local.branch_slug, local.deployment_params.default).vm_size
  }

  identity {
    type = "SystemAssigned"
  }


  azure_active_directory_role_based_access_control {
    managed = true
    admin_group_object_ids = lookup(local.deployment_params, local.branch_slug, local.deployment_params.default).admin_group_object_ids
    azure_rbac_enabled = true
  }

  network_profile {
    network_plugin  = "azure" 
    network_policy = "azure"
  }
   
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  }  
}

resource "azurerm_role_assignment" "acrpull" {
  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.this.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "reader" {
  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  role_definition_name             = "Reader"
  scope                            = azurerm_resource_group.this.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "network" {
  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  role_definition_name             = "Network Contributor"
  scope                            = azurerm_resource_group.this.id
  skip_service_principal_aad_check = true
}

resource "null_resource" "wait" {
  depends_on = [azurerm_kubernetes_cluster.this]
  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "azurerm_public_ip" "this" {
  depends_on          = [null_resource.wait]
  name                = local.simple_name
  resource_group_name = "${azurerm_resource_group.this.name}-nodes"
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_dns_a_record" "this" {
  name                = "@"
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = azurerm_resource_group.this.name
  ttl                 = 60
  records             = [azurerm_public_ip.this.ip_address]
}

resource "azurerm_dns_a_record" "wildcard" {
  name                = "*"
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = azurerm_resource_group.this.name
  ttl                 = 60
  records             = [azurerm_public_ip.this.ip_address]
}

resource "helm_release" "nginx_ingress" {
  depends_on       = [azurerm_public_ip.this]
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  wait             = false
  dynamic "set" {
    for_each = local.ingress_nginx_chart
    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "helm_release" "cert_manager" {
  depends_on       = [helm_release.nginx_ingress]
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  wait             = false
  dynamic "set" {
    for_each = local.cert_manager_chart
    content {
      name  = set.key
      value = set.value
    }
  }
}


resource "helm_release" "loki_stack" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  namespace        = "loki"
  create_namespace = true
  wait             = false
  dynamic "set" {
    for_each = local.loki_stack_chart
    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "helm_release" "argocd" {
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argo-cd"
  create_namespace = true
  wait             = false
  dynamic "set" {
    for_each = local.argocd_chart
    content {
      name  = set.key
      value = set.value
    }
  }
}
