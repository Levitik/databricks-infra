# # Databricks Automatic Identity Manaement: AIM, works in combination with Just-In-Time provisioning (JIT) and Identity federation to automatically provision users intot databricks
# # AIM made users, roups and SPN available into search engine by making rapgh API to entraid. So we will only provision roups and SPN, users beloning to a roup with rigght 
# # permission will get access to databricks and provisioned automatically after the first login usin JIT
# # See this video for mre details: https://www.youtube.com/watch?v=bJ98nufBSQM


# Collecting Azure AD groups for use in Databricks group management
data "azuread_group" "entraid_groups" {
  for_each     = toset(local.entraid_groups_name)
  display_name = each.value
}

# Entra id group provisioning into databricks account groups
resource "databricks_group" "entraid_groups" {
  provider     = databricks.account
  for_each     = data.azuread_group.entraid_groups
  display_name = each.value.display_name
  external_id  = each.value.object_id
}

# Add account groups to databricks account 
resource "databricks_group" "account_groups" {
  provider     = databricks.account
  for_each     = toset(local.account_groups_name)
  display_name = each.key
}

# Assign account admin role to account groups
resource "databricks_group_role" "account_admin" {
  provider = databricks.account
  for_each = toset(local.account_groups_admin)
  group_id = databricks_group.account_groups[each.key].id
  role     = "account_admin"
}

# Assign entra id group to account groups
resource "databricks_group_member" "account_groups_membership" {
  provider  = databricks.account
  for_each  = toset(local.account_groups_members)
  group_id  = databricks_group.account_groups[split("|", each.key)[0]].id
  member_id = databricks_group.entraid_groups[split("|", each.key)[1]].id
}

# Assign group to workspace (only account groups can be directly assin to workspace)
resource "databricks_mws_permission_assignment" "group_assignment" {
  provider     = databricks.account
  for_each     = toset(local.account_groups_name)
  principal_id = databricks_group.account_groups[each.key].id
  permissions  = ["USER"]
  workspace_id = var.databricks_workspace_id
}




# locals {
#   entraid_users = flatten([
#     for group_name in local.entraid_groups_name : [
#       for member_object_id in data.azuread_group.entraid_groups[group_name].members : member_object_id
#     ]
#   ])
#   entraid_groups_users_object_id_map = {
#     for groups_users_object_id in local.entraid_groups_users_object_id_list : groups_users_object_id => {
#       user_principal_name = data.azuread_user.entraid_users[groups_users_object_id].user_principal_name
#       display_name        = data.azuread_user.entraid_users[groups_users_object_id].display_name
#       object_id           = data.azuread_user.entraid_users[groups_users_object_id].object_id
#     }
#   }
# }

#Collecting Azure AD users for use in Databricks user management
# data "azuread_user" "entraid_users" {
#   for_each  = toset(local.entraid_users)
#   object_id = each.key
# }

# output "members_of_analysts_group" {
#   value = data.azuread_group.entraid_groups
# }

# Add user to databricks account
# resource "databricks_user" "entraid_user" {
#   provider     = databricks.account
#   for_each     = toset(local.entraid_users)
#   user_name    = data.azuread_user.entraid_users[each.key].user_principal_name
#   display_name = data.azuread_user.entraid_users[each.key].display_name
#   external_id  = data.azuread_user.entraid_users[each.key].object_id
# }

# Add group to databricks account
# resource "databricks_group" "entraid_groups" {
#   provider     = databricks.account
#   for_each     = toset(local.entraid_groups_name)
#   display_name = data.azuread_group.entraid_groups[each.key].display_name
#   external_id  = data.azuread_group.entraid_groups[each.key].object_id
# }

# Assign group to workspace
# resource "databricks_mws_permission_assignment" "group_assignment" {
#   provider     = databricks.account
#   for_each     = toset(local.entraid_groups_name)
#   principal_id = databricks_group.entraid_groups[each.key].id
#   permissions  = ["USER"]
#   workspace_id = var.databricks_workspace_id
# }

# resource "databricks_mws_permission_assignment" "group_assignment" {
#   provider     = databricks.account
#   for_each     = data.azuread_group.entraid_groups
#   principal_id = databricks_group.entraid_groups[each.key].id
#   permissions  = ["USER"]
#   workspace_id = var.databricks_workspace_id
# }
