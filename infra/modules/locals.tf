# locals.tf
locals {

  ########################################################################
  ######################        Databricks Catalogs   ####################   
  ########################################################################
  catalog_yaml      = yamldecode(file("${path.module}/yaml/catalogs.yaml"))
  standard_catalogs = local.catalog_yaml.standard_catalogs
  catalogs = {
    for cat_name, cat_def in local.standard_catalogs :
    cat_name => [
      for schema_name, schema_def in cat_def.schemas : schema_name
    ]
  }
  schemas = flatten([
    for cat, schemas in local.catalogs : [
      for s in schemas : "${cat}.${s}"
    ]
  ])
  catalogs_level_permissions = {
    for cat_name, cat_def in local.standard_catalogs :
    cat_name => {
      for env in distinct(flatten([
        for group_name, group_envs in cat_def.grants : [
          for env_key, env_value in group_envs : env_key
        ]
      ])) :
      env => {
        for group_name, group_envs in cat_def.grants :
        "${cat_name}|${group_name}" => {
          group_name       = group_name
          permission_level = group_envs[env]
        }
        if contains(keys(group_envs), env) # Only include groups that have permissions for this environment
      }
    }
  }
  schema_permission_configs = {
    for cat_name, cat_def in local.standard_catalogs :
    cat_name => {
      for schema_name, schema_def in cat_def.schemas :
      "${cat_name}.${schema_name}" => {
        for env in distinct(flatten([
          for group_name, group_envs in schema_def.grants : [
            for env_key, env_value in group_envs : env_key
          ]
        ])) :
        env => {
          for group_name, group_envs in schema_def.grants :
          "${cat_name}.${schema_name}|${group_name}" => {
            group_name       = group_name
            permission_level = group_envs[env]
          }
          if contains(keys(group_envs), env) # Only include groups that have permissions for this environment
        }
      }
    }
  }
  schema_level_permissions_prerequisites = {
    for cat_name, schema_def in local.schema_permission_configs :
    cat_name => {
      for env in distinct(flatten([
        for schema_name, schema_envs in schema_def : keys(schema_envs)
      ])) :
      env => {
        for group_name in distinct(flatten([
          for schema_name, schema_envs in schema_def : [
            for perm_key, perm_value in try(schema_envs[env], {}) : perm_value.group_name
          ]
        ])) :
        "${cat_name}|${group_name}" => {
          group_name       = group_name
          permission_level = ["USE CATALOG"] # Granting "USE CATALOG" at the catalog level as a prerequisite for any schema-level permissions
        }
      }
    }
  }
  schema_level_permissions = merge([
    for cat_name, schema_permission_configs in local.schema_permission_configs : schema_permission_configs
  ]...)


  foreign_catalogs = local.catalog_yaml.foreign_catalogs
  f_catalogs = [
    for cat_name, cat_def in local.foreign_catalogs : cat_name
  ]

  f_catalogs_level_permissions = {
    for cat_name, cat_def in local.foreign_catalogs :
    cat_name => {
      for env in distinct(flatten([
        for group_name, group_envs in cat_def.grants : [
          for env_key, env_value in group_envs : env_key
        ]
      ])) :
      env => {
        for group_name, group_envs in cat_def.grants :
        "${cat_name}|${group_name}" => {
          group_name       = group_name
          permission_level = group_envs[env]
        }
        if contains(keys(group_envs), env) # Only include groups that have permissions for this environment
      }
    }
  }

  f_schema_permission_configs = {
    for cat_name, cat_def in local.foreign_catalogs :
    cat_name => {
      for schema_name, schema_def in cat_def.schemas :
      "${cat_name}.${schema_name}" => {
        for env in distinct(flatten([
          for group_name, group_envs in schema_def.grants : [
            for env_key, env_value in group_envs : env_key
          ]
        ])) :
        env => {
          for group_name, group_envs in schema_def.grants :
          "${cat_name}.${schema_name}|${group_name}" => {
            group_name       = group_name
            permission_level = group_envs[env]
          }
          if contains(keys(group_envs), env) # Only include groups that have permissions for this environment
        }
      }
    }
  }
  f_schema_level_permissions_prerequisites = {
    for cat_name, schema_def in local.f_schema_permission_configs :
    cat_name => {
      for env in distinct(flatten([
        for schema_name, schema_envs in schema_def : keys(schema_envs)
      ])) :
      env => {
        for group_name in distinct(flatten([
          for schema_name, schema_envs in schema_def : [
            for perm_key, perm_value in try(schema_envs[env], {}) : perm_value.group_name
          ]
        ])) :
        "${cat_name}|${group_name}" => {
          group_name       = group_name
          permission_level = ["USE CATALOG"] # Granting "USE CATALOG" at the catalog level as a prerequisite for any schema-level permissions
        }
      }
    }
  }
  f_schema_level_permissions = merge([
    for cat_name, schema_permission_configs in local.f_schema_permission_configs : schema_permission_configs
  ]...)


  ########################################################################
  ######################        Databricks Users      ####################   
  ########################################################################
  users_yaml                = yamldecode(file("${path.module}/yaml/users.yaml"))
  entraid_groups            = local.users_yaml.entraid_groups
  databricks_account_groups = local.users_yaml.databricks_account_groups
  entraid_groups_name = [
    for group in local.entraid_groups : group.names
  ]
  databricks_account_groups_name = [
    for group in local.databricks_account_groups : group.names
  ]

  ########################################################################
  ###################       Workspace folders         ####################   
  ########################################################################
  # Databricks workspace folders are defined in a separate YAML file for better readability and maintainability.
  raw_folders   = yamldecode(file("${path.module}/yaml/folders.yaml")).workspace_folders
  reserved_keys = toset(["names", "sub_folders"])
  flatten_folders = [
    for folder in local.raw_folders : {
      parent   = folder.names
      children = try(folder.sub_folders, [])
    }
  ]
  parent_folders = [
    for parent in local.raw_folders : "${parent.names}" if "${parent.names}" != "Shared" # Exclude the "Shared" folder from the list of parent folders since it will be created with different permissions
  ]
  child_folders = flatten([
    for parent in local.raw_folders : [
      for child in try(parent.sub_folders, []) : concat(
        # This will create entries like "Shared/Libraries" for the example YAML structure
        ["${parent.names}/${child.names}"],
        # If there are further nested sub-folders, we can handle them recursively:
        # This assumes a maximum of 3 levels (parent -> child -> grandchild). For deeper nesting, this logic would need to be extended.
        # If there are no sub-folders, the try() will return an empty list and won't add anything.
        # e.g., if there were a "Shared/Libraries/Utils" folder, it would add "Shared/Libraries/Utils" to the list.
        [
          for grandchild in try(child.sub_folders, []) : "${parent.names}/${child.names}/${grandchild.names}"
        ]
      )
    ]
  ])
  all_folders = concat(local.parent_folders, local.child_folders)
  folder_permissions = merge(
    {
      for entry in local.raw_folders :
      entry.names => {
        for key, value in entry :
        "${entry.names}|${key}" => {
          group_name       = key
          permission_level = value
        }
        if !contains(toset(local.reserved_keys), key) # Exclude reserved keys like "names" and "sub_folders"
      }
    },
    #This will create entries like "Shared/Libraries" => { "Shared/Libraries|DataScientists" = { group_name = "DataScientists", permission_level = "read" }, ... }
    {
      for entry in flatten([
        for parent in local.raw_folders : [
          for child in try(parent.sub_folders, []) : {
            path  = "${parent.names}/${child.names}"
            child = child
          }
        ]
      ]) :
      entry.path => {
        for key, value in entry.child :
        "${entry.path}|${key}" => {
          group_name       = key
          permission_level = value
        }
        if !contains(toset(local.reserved_keys), key) # Exclude reserved keys like "names" and "sub_folders"
      }
    },
    # This will create entries like "Shared/Libraries/Utils" => { "Shared/Libraries/Utils|DataScientists" = { group_name = "DataScientists", permission_level = "read" }, ... }
    {
      for entry in flatten([
        for parent in local.raw_folders : [
          for child in try(parent.sub_folders, []) : [
            for grandchild in try(child.sub_folders, []) : {
              path       = "${parent.names}/${child.names}/${grandchild.names}"
              grandchild = grandchild
            }
          ]
        ]
      ]) :
      entry.path => {
        for key, value in entry.grandchild :
        "${entry.path}|${key}" => {
          group_name       = key
          permission_level = value
        }
        if !contains(toset(local.reserved_keys), key) # Exclude reserved keys like "names" and "sub_folders"
      }
    }
  )

  ########################################################################
  ###################       Databricks Compute        ####################   
  ########################################################################
  raw_computes = yamldecode(file("${path.module}/yaml/computes.yaml")).computes
  computes_configs = {
    for raw_computes in local.raw_computes : raw_computes.names => {
      config      = raw_computes.config
      permissions = raw_computes.permissions
    }
  }
  all_computes = {
    for compute_name, compute_configs in local.computes_configs :
    compute_name => {
      for env in distinct(flatten([
        for group_name, group_envs in compute_configs.permissions : [
          for env_key, env_value in group_envs : env_key
        ]
      ])) :
      env => {
        for group_name, group_envs in compute_configs.permissions :
        "${compute_name}|${group_name}" => {
          group_name       = group_name
          permission_level = group_envs[env]
        }
        if contains(keys(group_envs), env) # Only include groups that have permissions for this environment
      }
    }
  }






































  # Helper to recursively flatten the structure
  # workspace_folders = merge(
  #   # Top-level folders
  #   {
  #     for folder in local.flatten_folders :
  #     folder.parent => [for sub in folder.children : sub.names]
  #   },

  #   # Nested folders (e.g., Teams/dataplatform)
  #   merge([
  #     for folder in local.flatten_folders : (
  #       length(folder.children) > 0 ?
  #       merge([
  #         for sub in folder.children : (
  #           try(sub.sub_folders, null) != null ?
  #           {
  #             "${folder.parent}/${sub.names}" = [for subsub in sub.sub_folders : subsub.names]
  #           } : {}
  #         )
  #       ]...)
  #       : {}
  #     )
  #   ]...)
  # )

  # all_folders = flatten([
  #   for parent, subs in local.workspace_folders : [
  #     for sub in subs : "${parent}/${sub}"
  #   ]
  # ])

}
