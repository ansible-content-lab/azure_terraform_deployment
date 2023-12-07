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
  name     = "${var.resource_group}"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "aap" {
  name                = "${var.deployment_id}-aap-vn"
  location            = azurerm_resource_group.aap.location
  resource_group_name = azurerm_resource_group.aap.name
  address_space       = ["${var.infrastructure_vpc_cidr}"]
}

resource "azurerm_subnet" "aap" {
  name                 = "${var.deployment_id}-aap-sn"
  resource_group_name  = azurerm_resource_group.aap.name
  virtual_network_name = azurerm_virtual_network.aap.name
  address_prefixes     = ["${var.infrastructure_vpc_subnet_cidr_postgres}"]
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
  name                = "aap.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.aap.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "aap" {
  name                  = "aapVnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.aap.name
  virtual_network_id    = azurerm_virtual_network.aap.id
  resource_group_name = azurerm_resource_group.aap.name
}

#
# Database
module "db" {
  #depends_on = [random_string.deployment_id]
  depends_on = [azurerm_private_dns_zone_virtual_network_link.aap]

  source = "./modules/db"

  deployment_id = "${var.deployment_id}"
  resource_group = azurerm_resource_group.aap.name
  location = azurerm_resource_group.aap.location
  infrastructure_db_username = "${var.infrastructure_db_username}"
  infrastructure_db_password = "${var.infrastructure_db_password}"
  infrastructure_db_engine_version = "${var.infrastructure_db_engine_version}"
  infrastructure_db_storage_mb = "${var.infrastructure_db_storage_mb}"
  infrastructure_db_instance_sku = "${var.infrastructure_db_instance_sku}"
  subnet_id = azurerm_subnet.aap.id
  private_dns_zone_id = azurerm_private_dns_zone.aap.id
}
