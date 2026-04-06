# Define Terraform provider
terraform {
  required_version = "~> 1.14.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.38"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.5.0"
    }
  }
  backend "azurerm" {
    use_oidc             = true # Can also be set via `ARM_USE_OIDC` environment variable.
    use_azuread_auth     = true # Can also be set via `ARM_USE_AZUREAD` environment variable.
    tenant_id            = ""   # Can also be set via `ARM_TENANT_ID` environment variable.
    subscription_id      = ""   # Can also be set via `ARM_SUBSCRIPTION_ID` environment variable.
    client_id            = ""   # Can also be set via `ARM_CLIENT_ID` environment variable.
    resource_group_name  = ""
    storage_account_name = "" # Can be passed via `-backend-config=`"storage_account_name=<storage account name>"` in the `init` command.
    container_name       = "" # Can be passed via `-backend-config=`"container_name=<container name>"` in the `init` command.
    key                  = "" # Can be passed via `-backend-config=`"key=<blob key name>"` in the `init` command. 
  }
}

# Define the Azure provider
provider "azurerm" {
  features {}
  storage_use_azuread = true
  use_oidc            = true
  client_id           = var.aad_client_id
  tenant_id           = var.aad_tenant_id
  subscription_id     = var.aad_subscription_id
}

# Define the Databricks Workspace provider
provider "databricks" {
  host          = var.databricks_workspace_url
  azure_use_msi = true
  # azure_tenant_id     = var.aad_tenant_id
  # azure_client_id     = var.aad_client_id
  # azure_client_secret = var.aad_client_secret
  #auth_type     = "azure_cli"
}

# Define the Databricks Account provider
provider "databricks" {
  alias               = "account"
  host                = "https://accounts.azuredatabricks.net"
  account_id          = var.databricks_account_id
  azure_tenant_id     = var.aad_tenant_id
  azure_client_id     = var.aad_client_id
  azure_client_secret = var.aad_client_secret
}

provider "azuread" {
  #use_msi   = true
  client_id = var.aad_client_id
  tenant_id = var.aad_tenant_id
}
