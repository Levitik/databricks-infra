#######################################################################
###############           Common variables              ###############
#######################################################################
variable "location" {
  type        = string
  description = "The location of the storage account"
}

variable "environment" {
  type        = string
  description = "The environment for the resources"
}

variable "databricks_workspace_rg" {
  type        = string
  description = "The resource group name for the Databricks workspace"
}

#######################################################################
###############           Storage Account               ###############
#######################################################################
variable "storage_account_name" {
  type        = string
  description = "The name of the storage account"
}

#######################################################################
###############          Access Connector               ###############
#######################################################################
variable "databricks_access_connector_name" {
  type        = string
  description = "The name of the Databricks access connector"
}
