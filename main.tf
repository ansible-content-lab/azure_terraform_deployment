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
#
# Network
#
module "vnet" {
  depends_on = [random_string.deployment_id,azurerm_resource_group.aap]
  
  source = "./modules/vnet"
  deployment_id = var.deployment_id == "" ? random_string.deployment_id[0].id : var.deployment_id
  persistent_tags = local.persistent_tags
  location = var.location
  resource_group = var.resource_group
}
#
# Database
module "db" {
  depends_on = [module.vnet]

  source = "./modules/db"
  deployment_id = var.deployment_id
  resource_group = azurerm_resource_group.aap.name
  location = azurerm_resource_group.aap.location
  infrastructure_db_username = var.infrastructure_db_username
  infrastructure_db_password = var.infrastructure_db_password
  infrastructure_db_engine_version = var.infrastructure_db_engine_version
  infrastructure_db_storage_mb = var.infrastructure_db_storage_mb
  infrastructure_db_instance_sku = var.infrastructure_db_instance_sku
  subnet_id = module.vnet.aap_infrastructure_postgres_subnet_id
  private_dns_zone_id = module.vnet.aap_private_dns_zone_id
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
  subnet_id = values(module.vnet.infrastructure_subnets)[0]
}
