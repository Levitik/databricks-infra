
# Assign <<Storage Blob Data Contributor>> role to the Databricks Access Connector on storage account level
resource "azurerm_role_assignment" "storage_account" {
  scope                = azurerm_databricks_access_connector.managed.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.managed.identity[0].principal_id
}

# Assign <<Storage Blob Data Contributor>> role to the Databricks Access Connector on storage container level
resource "azurerm_role_assignment" "storage_container" {
  for_each             = toset(keys(local.catalogs))
  scope                = azurerm_storage_container.managed[each.key].id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.managed.identity[0].principal_id
}
