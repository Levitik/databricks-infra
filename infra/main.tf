module "databricks-infra" {
  providers = {
    databricks.account = databricks.account
  }
  source                           = "./modules"
  location                         = var.location
  databricks_workspace_rg          = var.databricks_workspace_rg
  storage_account_name             = var.storage_account_name
  databricks_access_connector_name = var.databricks_access_connector_name
  environment                      = var.environment
  databricks_workspace_id          = var.databricks_workspace_id
}
