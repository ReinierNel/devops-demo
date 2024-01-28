variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "key_vault_crypto_officer" {
  type        = list(string)
  description = "Client ID's of users and Service Principals that sould get the Key Vault Crypto Officer role"
}

variable "key_vault_secrets_officer" {
  type        = list(string)
  description = "Client ID's of users and Service Principals that sould get the Key Vault Secrets Officer role"
}
