#  https://learn.microsoft.com/en-us/azure/databricks/security/auth/access-control/


#######################################################################
#########    Standard Catalog: Catalog level permission      ###########
#######################################################################

resource "databricks_grants" "standard_catalog_level_permissions" {
  for_each = local.catalogs_level_permissions
  catalog  = databricks_catalog.managed[each.key].name
  dynamic "grant" {
    for_each = merge(try(each.value["all"], {}), try(each.value["${var.environment}"], {}))
    content {
      principal  = grant.value.group_name
      privileges = grant.value.permission_level
    }
  }
  depends_on = [databricks_mws_permission_assignment.group_assignment]
}

#######################################################################
#########    Standard Catalog: Schema level permission      ###########
#######################################################################

# Granting "USE CATALOG" at the catalog level as a prerequisite for any schema-level permissions
resource "databricks_grants" "standard_schema_prerequisites_permissions" {
  for_each = local.schema_level_permissions_prerequisites
  catalog  = databricks_catalog.managed[each.key].name
  dynamic "grant" {
    for_each = merge(try(each.value["all"], {}), try(each.value["${var.environment}"], {}))
    content {
      principal  = grant.value.group_name
      privileges = grant.value.permission_level
    }
  }
  depends_on = [databricks_mws_permission_assignment.group_assignment]
}

resource "databricks_grants" "standard_schema_level_permissions" {
  for_each = local.schema_level_permissions
  schema   = databricks_schema.managed[each.key].id
  dynamic "grant" {
    for_each = merge(try(each.value["all"], {}), try(each.value["${var.environment}"], {}))
    content {
      principal  = grant.value.group_name
      privileges = grant.value.permission_level
    }
  }
  depends_on = [databricks_mws_permission_assignment.group_assignment]
}

#####################################################################
#######    Foreign Catalog: Catalog level permission      ###########
#####################################################################

resource "databricks_grants" "foreign_catalog_level_permissions" {
  for_each = local.f_catalogs_level_permissions
  catalog  = databricks_catalog.foreign[each.key].name
  dynamic "grant" {
    for_each = merge(try(each.value["all"], {}), try(each.value["${var.environment}"], {}))
    content {
      principal  = grant.value.group_name
      privileges = grant.value.permission_level
    }
  }
  depends_on = [databricks_mws_permission_assignment.group_assignment]
}

#######################################################################
#########    Foreign Catalog: Schema level permission      ###########
#######################################################################

# Granting "USE CATALOG" at the catalog level as a prerequisite for any schema-level permissions
resource "databricks_grants" "foreign_schema_prerequisites_permissions" {
  for_each = local.f_schema_level_permissions_prerequisites
  catalog  = databricks_catalog.foreign[each.key].name
  dynamic "grant" {
    #for_each = merge(try(each.value["all"], {}), try(each.value["${var.environment}"], {}))
    # for_each = [
    #   for env, permissions in each.value : permissions if env == "all" || env == var.environment
    # ]
    for_each = merge([
      for env, permissions in each.value : permissions if env == "all" || env == var.environment
    ]...)

    content {
      principal  = grant.value.group_name
      privileges = grant.value.permission_level
    }
  }
  depends_on = [databricks_mws_permission_assignment.group_assignment]
}

# # resource "databricks_grants" "standard_schema_level_permissions" {
# #   for_each = local.schema_level_permissions
# #   schema   = databricks_schema.managed[each.key].id
# #   dynamic "grant" {
# #     for_each = merge(try(each.value["all"], {}), try(each.value["${var.environment}"], {}))
# #     content {
# #       principal  = grant.value.group_name
# #       privileges = grant.value.permission_level
# #     }
# #   }
# #   depends_on = [databricks_mws_permission_assignment.group_assignment]
# # }
