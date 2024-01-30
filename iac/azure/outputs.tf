resource "local_file" "output_env_file" {
  filename = "${path.module}/env.sh"
  content  = <<EOF
#!/bin/bash
export CONTAINER_REGISTRY_URL="${azurerm_container_registry.this.login_server}"
export CONTAINER_REGISTRY_NAME="${azurerm_container_registry.this.name}"
export AZ_AKS_CLUSTER_RESOURCE_GROUP_NAME="${azurerm_kubernetes_cluster.this.resource_group_name}"
export AZ_AKS_CLUSTER_NAME="${azurerm_kubernetes_cluster.this.name}"
export AZ_TENANT_ID="e9a49ca6-aef5-4fe3-80b8-87b7406d5bf0"
export AZ_DNS_ZONE_NAME="${lookup(local.deployment_params, local.branch_slug, local.deployment_params.default).dns_zone_name}.${local.root_dns_zone}"
EOF
}

resource "local_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig"
  content  = azurerm_kubernetes_cluster.this.kube_admin_config_raw
}