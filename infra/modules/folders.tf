# resource "databricks_directory" "folders" {
#   for_each = toset(local.all_folders)
#   path     = "/${each.value}"
# }

# # resource "databricks_permissions" "folder_permissions" {
# #   for_each       = { for folder, permissions in local.folder_permissions : folder => permissions if permissions != {} } # Exclude folders with no explicit permissions
# #   directory_path = "/${each.key}"
# #   dynamic "access_control" {
# #     for_each = each.value
# #     content {
# #       group_name       = access_control.value.group_name
# #       permission_level = access_control.value.permission_level
# #     }
# #   }
# #   depends_on = [databricks_directory.folders, databricks_mws_permission_assignment.group_assignment]
# # }


# resource "databricks_permissions" "folder_permissions" {
#   for_each       = { for folder, permissions in local.folder_permissions : folder => permissions if permissions != {} } # Exclude folders with no explicit permissions
#   directory_path = databricks_directory.folders[each.key].path
#   dynamic "access_control" {
#     for_each = each.value
#     content {
#       group_name       = access_control.value.group_name
#       permission_level = access_control.value.permission_level
#     }
#   }
#   depends_on = [databricks_mws_permission_assignment.group_assignment]
# }
