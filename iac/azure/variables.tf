variable "branch_name" {
  type = string
}

variable "tenant_id" {
  type      = string
  sensitive = true
}

variable "subscription_id" {
  type      = string
  sensitive = true
}

# variable "github_pat" {
#   type      = string
#   sensitive = true
# }

variable "ci_runner_public_ip" {
  type = string
  description = "The public IP address of the ci runner needed to deploy manifests"
  default = ""
}