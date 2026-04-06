resource "databricks_sql_endpoint" "serverless_sql_warehouse" {
  for_each                  = local.computes_configs
  name                      = "${each.key}_COMPUTE"
  cluster_size              = each.value.config.cluster_size
  max_num_clusters          = each.value.config.max_num_clusters
  min_num_clusters          = each.value.config.min_num_clusters
  auto_stop_mins            = each.value.config.auto_stop_mins
  enable_serverless_compute = each.value.config.enable_serverless_compute
  tags {
    custom_tags {
      key   = "ManagedBy"
      value = "Terraform"
    }

  }
}

resource "databricks_permissions" "warehouse_permissions" {
  for_each        = local.all_computes
  sql_endpoint_id = databricks_sql_endpoint.serverless_sql_warehouse[each.key].id
  dynamic "access_control" {
    for_each = merge(try(each.value["all"], {}), try(each.value["${var.environment}"], {}))
    content {
      group_name       = access_control.value.group_name
      permission_level = access_control.value.permission_level
    }
  }
  depends_on = [databricks_mws_permission_assignment.group_assignment]
}
