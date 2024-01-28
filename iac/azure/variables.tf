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

variable "github_pat" {
  type      = string
  sensitive = true
}
