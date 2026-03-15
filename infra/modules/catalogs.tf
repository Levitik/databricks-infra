#######################################################################
###############           Standard Catalog              ###############
#######################################################################
# Databricks Catalogs
resource "databricks_catalog" "managed" {
  for_each       = toset(keys(local.catalogs))
  name           = "${var.environment}-${each.key}"
  comment        = "${each.key} Catalog provisioned by Terraform"
  isolation_mode = "ISOLATED"
  #owner        = databricks_group.uc_admins.display_name
  storage_root = databricks_external_location.managed[each.key].url
  properties = {
    purpose     = "${each.key}"
    environment = var.environment
  }
}

# Databricks Schema (Database)
resource "databricks_schema" "managed" {
  for_each     = toset(local.schemas)
  catalog_name = databricks_catalog.managed[split(".", "${each.key}")[0]].id
  name         = split(".", "${each.key}")[1]
  comment      = "this database is managed by terraform"
  properties = {
    kind = "various"
  }
}

#######################################################################
###############            Foreign Catalog              ###############
#######################################################################







#######################################################################
###############            Default Catalog              ###############
#######################################################################
