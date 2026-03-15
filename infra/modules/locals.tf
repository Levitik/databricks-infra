# locals.tf
locals {
  catalog_yaml = yamldecode(file("${path.module}/catalogs.yaml"))

  catalog_template = merge(
    local.catalog_yaml.catalog_template,
    {
      for k, v in local.catalog_yaml : k => v if k != "catalog_template"
    }
  )

  catalogs = {
    for cat_name, cat_def in local.catalog_template : cat_name => cat_def.schemas
  }

  schemas = flatten([
    for cat, schemas in local.catalogs : [
      for s in schemas : "${cat}.${s}"
    ]
  ])
}
