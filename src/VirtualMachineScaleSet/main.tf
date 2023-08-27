terraform {

  backend "azurerm" {
    resource_group_name  = "rg-elearning-core-uks"
    storage_account_name = "academyone"
    container_name       = "tf-state"
    key                  = "vmss.tfstate"
  }

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

locals {
  first_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+wWK73dCr+jgQOAxNsHAnNNNMEMWOHYEccp6wJm2gotpr9katuF/ZAdou5AaW1C61slRkHRkpRRX9FA9CYBiitZgvCCz+3nWNN7l/Up54Zps/pHWGZLHNJZRYyAB6j5yVLMVHIHriY49d/GZTZVNB8GoJv9Gakwc/fuEZYYl4YDFiGMBP///TzlI4jhiJzjKnEvqPFki5p2ZRJqcbCiF4pJrxUQR/RXqVFQdbRLZgYfJ8xGB878RENq3yQ39d8dVOkq4edbkzwcUmwwwkYVPIoDGsYLaRHnG+To7FvMeyO7xDVQkMKzopTQV8AuKpyvpqu0a9pWOMaiCyDytO7GGN you@me.com"
}


resource "azurecaf_name" "vnet" {
  name          = "${var.project_name}-${var.environment}"
  resource_type = "azurerm_virtual_network"
  suffixes      = [var.location_short]
  clean_input   = true
}

resource "azurerm_virtual_network" "vnet" {
  name                = azurecaf_name.vnet.result
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurecaf_name" "snet" {
  name          = "${var.project_name}-${var.environment}"
  resource_type = "azurerm_subnet"
  suffixes      = [var.location_short, "001"]
  clean_input   = true
}

resource "azurerm_subnet" "snet" {
  name                 = azurecaf_name.snet.result
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurecaf_name" "vmss" {
  name          = "${var.project_name}-${var.environment}"
  resource_type = "azurerm_linux_virtual_machine_scale_set"
  suffixes      = [var.location_short]
  clean_input   = true
}

resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                            = azurecaf_name.vmss.result
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  sku                             = "Standard_B2ms"
  instances                       = 1
  admin_username                  = "adminuser"
  admin_password                  = "Xyzabc123!"
  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic-vmss-${var.project_name}-${var.environment}-${var.location_short}"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.snet.id
    }
  }

  tags = local.default_tags
}

resource "azurerm_virtual_machine_scale_set_extension" "vmsse" {
  name                         = "build-agent-extension"
  virtual_machine_scale_set_id = azurerm_linux_virtual_machine_scale_set.vmss.id
  publisher                    = "Microsoft.Azure.Extensions"
  type                         = "CustomScript"
  type_handler_version         = "2.1"
  settings = jsonencode({
    "script" : "https://raw.githubusercontent.com/rlightley/Devops.Azure.BuildAgents/main/.github/config.sh"
  })
}

# resource "azurerm_monitor_autoscale_setting" "example" {
#   name                = "myAutoscaleSetting"
#   resource_group_name = azurerm_resource_group.example.name
#   location            = azurerm_resource_group.example.location
#   target_resource_id  = azurerm_linux_virtual_machine_scale_set.example.id

#   profile {
#     name = "defaultProfile"

#     capacity {
#       default = 1
#       minimum = 1
#       maximum = 10
#     }

#     rule {
#       metric_trigger {
#         metric_name        = "Percentage CPU"
#         metric_resource_id = azurerm_linux_virtual_machine_scale_set.example.id
#         time_grain         = "PT1M"
#         statistic          = "Average"
#         time_window        = "PT5M"
#         time_aggregation   = "Average"
#         operator           = "GreaterThan"
#         threshold          = 75
#         metric_namespace   = "microsoft.compute/virtualmachinescalesets"
#         dimensions {
#           name     = "AppName"
#           operator = "Equals"
#           values   = ["App1"]
#         }
#       }

#       scale_action {
#         direction = "Increase"
#         type      = "ChangeCount"
#         value     = "1"
#         cooldown  = "PT1M"
#       }
#     }

#     rule {
#       metric_trigger {
#         metric_name        = "Percentage CPU"
#         metric_resource_id = azurerm_linux_virtual_machine_scale_set.example.id
#         time_grain         = "PT1M"
#         statistic          = "Average"
#         time_window        = "PT5M"
#         time_aggregation   = "Average"
#         operator           = "LessThan"
#         threshold          = 25
#       }

#       scale_action {
#         direction = "Decrease"
#         type      = "ChangeCount"
#         value     = "1"
#         cooldown  = "PT1M"
#       }
#     }
#   }

#   predictive {
#     scale_mode      = "Enabled"
#     look_ahead_time = "PT5M"
#   }

#   notification {
#     email {
#       send_to_subscription_administrator    = true
#       send_to_subscription_co_administrator = true
#       custom_emails                         = ["admin@contoso.com"]
#     }
#   }
# }
