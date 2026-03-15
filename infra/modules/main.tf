
#storage account for managed tables
resource "azurerm_storage_account" "managed" {
  name                     = var.storage_account_name
  location                 = var.location
  resource_group_name      = var.databricks_workspace_rg
  account_tier             = "Standard"
  account_replication_type = "GRS"
  is_hns_enabled           = true
}

#storage container for managed tables
resource "azurerm_storage_container" "managed" {
  for_each              = toset(keys(local.catalogs))
  name                  = each.key
  storage_account_id    = azurerm_storage_account.managed.id
  container_access_type = "private"
}

# Databricks Access Connector 
resource "azurerm_databricks_access_connector" "managed" {
  name                = var.databricks_access_connector_name
  location            = var.location
  resource_group_name = var.databricks_workspace_rg
  identity {
    type = "SystemAssigned"
  }
}

# Databricks Storage Credential
resource "databricks_storage_credential" "managed" {
  name = "${var.environment}-${azurerm_databricks_access_connector.managed.name}"
  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.managed.id
  }
  isolation_mode = "ISOLATION_MODE_ISOLATED"
  comment        = "Managed Storage Account"
  depends_on     = [azurerm_role_assignment.storage_account, azurerm_role_assignment.storage_container]
}

# Databricks External Location
resource "databricks_external_location" "managed" {
  for_each        = toset(keys(local.catalogs))
  name            = "${var.environment}-${each.key}-ext-loc"
  isolation_mode  = "ISOLATION_MODE_ISOLATED"
  url             = format("abfss://%s@%s.dfs.core.windows.net", azurerm_storage_container.managed[each.key].name, azurerm_storage_account.managed.name)
  credential_name = databricks_storage_credential.managed.id
  #owner           = databricks_group.uc_admins.display_name
  comment    = "External Location"
  depends_on = [azurerm_role_assignment.storage_account, azurerm_role_assignment.storage_container]
}
