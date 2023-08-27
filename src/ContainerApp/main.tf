terraform {

  # uncomment for remote backend
  # backend "azurerm" {

  # }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.71.0"
    }

    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "2.0.0-preview3"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azurecaf" {

}

locals {
  default_tags = {
    Environment = var.environment
    CreatedBy   = "Terraform"
    Project     = var.project_name
  }
}

resource "azurecaf_name" "rg_name" {
  name          = "${var.project_name}-${var.environment}"
  resource_type = "azurerm_resource_group"
  suffixes      = [var.location_short]
  clean_input   = true
}

resource "azurerm_resource_group" "rg" {
  name     = azurecaf_name.rg_name.result
  location = var.location
  tags     = local.default_tags
}

resource "azurecaf_name" "law" {
  name          = "${var.project_name}-${var.environment}"
  resource_type = "azurerm_log_analytics_workspace"
  suffixes      = [var.location_short]
  clean_input   = true
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = azurecaf_name.law.result
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.default_tags
}

resource "azurerm_container_app_environment" "cae" {
  name                       = "cae-${var.project_name}-${var.environment}-${var.location_short}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  tags                       = local.default_tags
}
