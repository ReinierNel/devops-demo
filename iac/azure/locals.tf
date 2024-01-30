locals {
  branch_slug                       = basename(var.branch_name)                       # basename of branch name e.g. feature/mybanch will resove to mybanch
  full_name                         = "${local.branch_slug}-devops-demo"              # standard name for normal resoruces
  simple_name                       = substr("${local.branch_slug}devopsdemo", 0, 23) # smaller name for resoruces that has naming restrictions
  root_dns_zone                     = "reinier.co.za"                                 # must be in the same subscriptions
  root_dns_zone_resoruce_group_name = "manual"
  deployment_users                  = ["9ddeeb6e-4be6-44d0-af99-09bab6f1fad4", "2ad835e0-f658-4208-b207-73a2ff972ca4"]
  deployment_params = {
    main = {
      location                = "East US 2"
      vm_size                 = "Standard_B2ms"
      default_node_pool_count = 2
      tags = {
        notes = "cost 0.0416 in eastus2 @ 2024-01-27"
      }
      dns_zone_name = "devops-demo" # subdomain of root domain
      trusted_ip_addresses = ["165.255.240.143/32", var.ci_runner_public_ip]
      admin_group_object_ids = ["3f6dfc8b-0758-4228-8ba0-846970d6531f"]
    }
    default = {
      location                = "Central India"
      vm_size                 = "Standard_B2als_v2"
      default_node_pool_count = 1
      tags = {
        notes = "cost 0.0246 in eastus2 @ 2024-01-27"
      }
      dns_zone_name = "${local.branch_slug}.devops-demo" # subdomain of root domain
      trusted_ip_addresses = ["165.255.240.143/32", var.ci_runner_public_ip]
      admin_group_object_ids = ["3f6dfc8b-0758-4228-8ba0-846970d6531f"]
    }
  }
  tags = merge(lookup(local.deployment_params, local.branch_slug, local.deployment_params.default).tags, {
    branch = var.branch_name
    repo   = "https://github.com/ReinierNel/devops-demo"
  })
  ingress_nginx_chart = {
    "controller.replicaCount"                                                                                           = 1
    "controller.service.annotations.\"service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path\"" = "/healthz"
    "controller.service.annotations.\"service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group\""            = "${local.full_name}-nodes"
    "controller.service.annotations.\"service\\.beta\\.kubernetes\\.io/azure-pip-name\""                                = local.simple_name
  }
  cert_manager_chart = {
    "installCRDs" = "true"
  }
  loki_stack_chart = {
    "fluent-bit.enabled" = true
    "grafana.enabled"    = true
    "prometheus.enabled" = true
  }
  argocd_chart = {
    "crds.install" = true
  }
  external_secrets_chart = {
    "installCRDs" = true
  }
}
