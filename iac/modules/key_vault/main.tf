resource "azurerm_key_vault" "this" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  sku_name                    = "standard"
  enable_rbac_authorization   = true
}

resource "azurerm_role_assignment" "key_vault_crypto_officer" {
  for_each             = toset(var.key_vault_crypto_officer)
  principal_id         = each.value
  role_definition_name = "Key Vault Crypto Officer"
  scope                = azurerm_key_vault.this.id
}

resource "azurerm_role_assignment" "key_vault_secrets_officer" {
  for_each             = toset(var.key_vault_crypto_officer)
  principal_id         = each.value
  role_definition_name = "Key Vault Secrets Officer"
  scope                = azurerm_key_vault.this.id
}
