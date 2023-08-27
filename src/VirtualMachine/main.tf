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

resource "azurerm_network_interface" "nic" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}
