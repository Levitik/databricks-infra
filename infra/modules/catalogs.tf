# #######################################################################
# ###############        Standard Prerequisites           ###############
# #######################################################################

# #storage account for managed tables
# resource "azurerm_storage_account" "managed" {
#   name                          = var.storage_account_name
#   location                      = var.location
#   resource_group_name           = var.databricks_workspace_rg
#   account_tier                  = "Standard"
#   account_kind                  = "StorageV2"
#   account_replication_type      = "GRS"
#   is_hns_enabled                = true
#   https_traffic_only_enabled    = true
#   min_tls_version               = "TLS1_2"
#   public_network_access_enabled = false
#   blob_properties {
#     # change_feed_enabled = true
#     # versioning_enabled  = true
#     delete_retention_policy {
#       days = 7
#     }
#   }
# }

# #storage container for managed tables
# resource "azurerm_storage_container" "managed" {
#   for_each              = toset(keys(local.catalogs))
#   name                  = each.key
#   storage_account_id    = azurerm_storage_account.managed.id
#   container_access_type = "private"
# }

# # Databricks Access Connector 
# resource "azurerm_databricks_access_connector" "managed" {
#   name                = var.databricks_access_connector_name
#   location            = var.location
#   resource_group_name = var.databricks_workspace_rg
#   identity {
#     type = "SystemAssigned"
#   }
# }

# # Databricks Storage Credential
# resource "databricks_storage_credential" "managed" {
#   name = "${var.environment}-${azurerm_databricks_access_connector.managed.name}"
#   azure_managed_identity {
#     access_connector_id = azurerm_databricks_access_connector.managed.id
#   }
#   isolation_mode = "ISOLATION_MODE_ISOLATED"
#   comment        = "Managed Storage Account"
#   depends_on     = [azurerm_role_assignment.storage_account]
# }

# # Assign <<Storage Blob Data Contributor>> role to the Databricks Access Connector on storage account level
# resource "azurerm_role_assignment" "storage_account" {
#   scope                = azurerm_storage_account.managed.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azurerm_databricks_access_connector.managed.identity[0].principal_id
# }

# # Databricks External Location
# resource "databricks_external_location" "managed" {
#   for_each        = toset(keys(local.catalogs))
#   name            = "${var.environment}-${each.key}-ext-loc"
#   isolation_mode  = "ISOLATION_MODE_ISOLATED"
#   url             = format("abfss://%s@%s.dfs.core.windows.net", azurerm_storage_container.managed[each.key].name, azurerm_storage_account.managed.name)
#   credential_name = databricks_storage_credential.managed.id
#   #owner           = databricks_group.uc_admins.display_name
#   comment    = "External Location"
#   depends_on = [azurerm_role_assignment.storage_account]
# }

# # Assign <<Storage Blob Data Contributor>> role to the Databricks Access Connector on storage container level
# # resource "azurerm_role_assignment" "storage_container" {
# #   for_each             = toset(keys(local.catalogs))
# #   scope                = azurerm_storage_container.managed[each.key].id
# #   role_definition_name = "Storage Blob Data Contributor"
# #   principal_id         = azurerm_databricks_access_connector.managed.identity[0].principal_id
# # }

# #######################################################################
# ###############           Standard Catalog              ###############
# #######################################################################
# # Databricks Catalogs
# resource "databricks_catalog" "managed" {
#   for_each       = toset(keys(local.catalogs))
#   name           = "${var.environment}-${each.key}"
#   comment        = "${each.key} Catalog provisioned by Terraform"
#   isolation_mode = "ISOLATED"
#   #owner        = databricks_group.uc_admins.display_name
#   storage_root = databricks_external_location.managed[each.key].url
#   properties = {
#     purpose     = "${each.key}"
#     environment = var.environment
#   }
# }

# # Databricks Schema (Database)
# resource "databricks_schema" "managed" {
#   for_each     = toset(local.schemas)
#   catalog_name = databricks_catalog.managed[split(".", "${each.key}")[0]].id
#   name         = split(".", "${each.key}")[1]
#   comment      = "this database is managed by terraform"
#   properties = {
#     kind = "various"
#   }
# }

# #######################################################################
# ###############            Foreign Catalog              ###############
# #######################################################################
# # Databricks Catalogs
# resource "databricks_catalog" "foreign" {
#   for_each        = toset(local.f_catalogs)
#   name            = "${var.environment}-${each.key}"
#   connection_name = "snowflake_user"
#   comment         = "${each.key} Foreign Catalog provisioned by Terraform"
#   isolation_mode  = "ISOLATED"
#   options = {
#     database = upper("${each.key}")
#   }
#   properties = {
#     purpose     = "${each.key}"
#     environment = var.environment
#   }
# }

# # Return Databricks Catalogs Schema for use in permissions management
# # data "databricks_schemas" "foreign" {
# #   for_each     = toset(local.f_catalogs)
# #   catalog_name = databricks_catalog.foreign[each.key].name
# # }
# # #######################################################################
# # ###############            Default Catalog              ###############
# # #######################################################################
