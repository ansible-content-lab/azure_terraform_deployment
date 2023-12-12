locals {

  create_deployment_id = var.deployment_id != "" ? 0 : 1
  # Common tags to be assigned to all resources
  persistent_tags = {
    purpose = "automation"
    environment = "ansible-automation-platform"
    deployment = "aap-infrastructure-${var.deployment_id}"
  }
}

terraform {
  required_version = ">= 1.5.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.83.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.6.0"
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

  length = 8
  special = false
  upper = false
  numeric = false
}

resource "azurerm_resource_group" "aap" {
  name = var.resource_group
  location = var.location
  tags = local.persistent_tags
}

resource "azurerm_virtual_network" "aap" {
  depends_on = [ azurerm_resource_group.aap ]
  name = "${var.deployment_id}-aap-vn"
  location = azurerm_resource_group.aap.location
  resource_group_name = azurerm_resource_group.aap.name
  address_space = [var.infrastructure_vpc_cidr]
  tags = local.persistent_tags
}

resource "azurerm_subnet" "aap" {
  depends_on = [ azurerm_virtual_network.aap ]
  name = "${var.deployment_id}-aap-sn"
  resource_group_name  = azurerm_resource_group.aap.name
  virtual_network_name = azurerm_virtual_network.aap.name
  address_prefixes = [var.infrastructure_vpc_subnet_cidr_postgres]
  service_endpoints = ["Microsoft.Storage"]
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

resource "azurerm_subnet" "aap_controller" {
  depends_on = [ azurerm_virtual_network.aap ]
  name = "${var.deployment_id}-aap-controller-subnet"
  resource_group_name = azurerm_resource_group.aap.name
  virtual_network_name = azurerm_virtual_network.aap.name
  address_prefixes = ["172.16.0.0/24"]
}

resource "azurerm_private_dns_zone" "aap" {
  name = "aap.${var.deployment_id}.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.aap.name
  tags = local.persistent_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "aap" {
  depends_on = [ azurerm_private_dns_zone.aap ]
  name = "postgres-link"
  private_dns_zone_name = azurerm_private_dns_zone.aap.name
  virtual_network_id = azurerm_virtual_network.aap.id
  resource_group_name = azurerm_resource_group.aap.name
  tags = local.persistent_tags
}

#
# Database
module "db" {
  depends_on = [azurerm_private_dns_zone.aap, azurerm_subnet.aap]

  source = "./modules/db"

  deployment_id = var.deployment_id
  resource_group = azurerm_resource_group.aap.name
  location = azurerm_resource_group.aap.location
  infrastructure_db_username = var.infrastructure_db_username
  infrastructure_db_password = var.infrastructure_db_password
  infrastructure_db_engine_version = var.infrastructure_db_engine_version
  infrastructure_db_storage_mb = var.infrastructure_db_storage_mb
  infrastructure_db_instance_sku = var.infrastructure_db_instance_sku
  subnet_id = azurerm_subnet.aap.id
  private_dns_zone_id = azurerm_private_dns_zone.aap.id
  persistent_tags = local.persistent_tags
}
#
# VM Creation - controller
#
module "controller" {
  depends_on = [ module.db ]
  source = "./modules/vm"

  deployment_id = var.deployment_id
  resource_group = azurerm_resource_group.aap.name
  app_tag = "controller"
  persistent_tags = local.persistent_tags
  subnet_id = azurerm_subnet.aap_controller.id
}