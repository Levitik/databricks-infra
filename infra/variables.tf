# ------------------------
# Authentication Variables
# ------------------------

variable "aad_tenant_id" {
  type        = string
  description = "The id of the Azure Tenant to which all subscriptions belong"
}

variable "aad_subscription_id" {
  type        = string
  description = "The id of the Azure Subscription"
}

variable "aad_client_id" {
  type        = string
  description = "The client id of the Service Principal for interacting with Azure resources"
}

variable "aad_client_secret" {
  type        = string
  description = "The client secret of the Service Principal for interacting with Azure resources"
}

# --------------------
# Databricks Variables
# --------------------

variable "databricks_workspace_rg" {
  type        = string
  description = "The existing Resource Group where Databricks Workspace was deployed"
}

variable "databricks_workspace_id" {
  type        = string
  description = "The ID of the Databricks Workspace for this deployment"
}

variable "databricks_workspace_url" {
  type        = string
  description = "The URL of the Databricks Workspace for this deployment"
}

variable "databricks_account_id" {
  type        = string
  description = "The ID of the Databricks Account for this deployment"
}

# --------------------
# Common variables
# --------------------
variable "location" {
  type        = string
  description = "The location of the storage account"
}

variable "environment" {
  type        = string
  description = "The environment for the resources"
}

# -------------------------------------
# Storage account variables
# -------------------------------------
variable "storage_account_name" {
  type        = string
  description = "The name of the storage account"
}

# -------------------------------------
# Storage account variables
# -------------------------------------
variable "databricks_access_connector_name" {
  type        = string
  description = "The name of the Databricks access connector"
}
