locals {

  create_deployment_id = var.deployment_id != "" ? 0 : 1
  # Common tags to be assigned to all resources
  persistent_tags = {
    purpose = "automation"
    environment   = "ansible-automation-platform"
    deployment = "aap-infrastructure-${var.deployment_id}"
  }
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

#  subscription_id = "00000000-0000-0000-0000-000000000000"
#  tenant_id       = "11111111-1111-1111-1111-111111111111"
}

resource "random_string" "deployment_id" {
  count = local.create_deployment_id

  length   = 8
  special  = false
  upper = false
  numeric = false

}

resource "azurerm_resource_group" "aap" {
#  name     = "cahl-rgaap-on-azure"
  name     = "cahl-rg"
  location = "East US"
}

resource "azurerm_virtual_network" "aap" {
  name                = "${var.deployment_id}-aap-vn"
  location            = azurerm_resource_group.aap.location
  resource_group_name = azurerm_resource_group.aap.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "aap" {
  name                 = "${var.deployment_id}-aap-sn"
  resource_group_name  = azurerm_resource_group.aap.name
  virtual_network_name = azurerm_virtual_network.aap.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_private_dns_zone" "aap" {
  name                = "example.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.aap.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "aap" {
  name                  = "aapVnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.aap.name
  virtual_network_id    = azurerm_virtual_network.aap.id
  resource_group_name   = azurerm_resource_group.aap.name
}

resource "azurerm_postgresql_flexible_server" "aap" {
  name                   = "${var.deployment_id}-psqlflexibleserver"
  resource_group_name    = azurerm_resource_group.aap.name
  location               = azurerm_resource_group.aap.location
  version                = "13"
  delegated_subnet_id    = azurerm_subnet.aap.id
  private_dns_zone_id    = azurerm_private_dns_zone.aap.id
  administrator_login    = "psqladmin"
  administrator_password = "H@Sh1CoR3!"
  zone                   = "1"

  storage_mb = 32768

  sku_name   = "GP_Standard_D4s_v3"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.aap]

}
