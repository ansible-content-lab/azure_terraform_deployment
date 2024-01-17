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
  location = var.location
  name = var.resource_group
  tags = local.persistent_tags
}

#
# Network
#
module "vnet" {
  depends_on = [random_string.deployment_id,azurerm_resource_group.aap]
  source = "./modules/vnet"

  deployment_id = var.deployment_id == "" ? random_string.deployment_id[0].id : var.deployment_id
  location = var.location
  persistent_tags = local.persistent_tags
  resource_group = var.resource_group
}

#
# Database
module "db" {
  depends_on = [module.vnet]
  source = "./modules/db"

  deployment_id = var.deployment_id
  infrastructure_db_username = var.infrastructure_db_username
  infrastructure_db_password = var.infrastructure_db_password
  infrastructure_db_engine_version = var.infrastructure_db_engine_version
  infrastructure_db_storage_mb = var.infrastructure_db_storage_mb
  infrastructure_db_instance_sku = var.infrastructure_db_instance_sku
  location = azurerm_resource_group.aap.location
  persistent_tags = local.persistent_tags
  private_dns_zone_id = module.vnet.aap_private_dns_zone_id
  resource_group = azurerm_resource_group.aap.name
  subnet_id = module.vnet.aap_infrastructure_postgres_subnet_id
}

#
# VM Creation - controller
#
module "controller" {
  depends_on = [ module.db ]
  source = "./modules/vm"

  app_tag = "controller"
  count = var.infrastructure_controller_count
  deployment_id = var.deployment_id
  location = azurerm_resource_group.aap.location
  persistent_tags = local.persistent_tags
  resource_group = azurerm_resource_group.aap.name
  infrastructure_admin_username = var.infrastructure_admin_username
  aap_red_hat_username = var.aap_red_hat_username
  aap_red_hat_password = var.aap_red_hat_password
  subnet_id = values(module.vnet.infrastructure_subnets)[0]
}

#
# VM Creation - hub
#
module "hub" {
  depends_on = [ module.db ]
  source = "./modules/vm"

  app_tag = "hub"
  count = var.infrastructure_hub_count
  deployment_id = var.deployment_id
  location = azurerm_resource_group.aap.location
  persistent_tags = local.persistent_tags
  resource_group = azurerm_resource_group.aap.name
  aap_red_hat_username = var.aap_red_hat_username
  aap_red_hat_password = var.aap_red_hat_password
  infrastructure_admin_username = var.infrastructure_admin_username
  subnet_id = values(module.vnet.infrastructure_subnets)[0]
}

#
# VM Creation - execution
#
module "execution" {
  depends_on = [ module.db ]
  source = "./modules/vm"

  app_tag = "execution"
  count = var.infrastructure_execution_count
  deployment_id = var.deployment_id
  location = azurerm_resource_group.aap.location
  persistent_tags = local.persistent_tags
  resource_group = azurerm_resource_group.aap.name
  aap_red_hat_username = var.aap_red_hat_username
  aap_red_hat_password = var.aap_red_hat_password
  infrastructure_admin_username = var.infrastructure_admin_username
  subnet_id = values(module.vnet.infrastructure_subnets)[1]
}

#
# VM Creation - EDA
#
module "eda" {
  depends_on = [ module.db ]
  source = "./modules/vm"

  app_tag = "eda"
  count = var.infrastructure_eda_count
  deployment_id = var.deployment_id
  location = azurerm_resource_group.aap.location
  persistent_tags = local.persistent_tags
  resource_group = azurerm_resource_group.aap.name
  aap_red_hat_username = var.aap_red_hat_username
  aap_red_hat_password = var.aap_red_hat_password
  infrastructure_admin_username = var.infrastructure_admin_username
  subnet_id = values(module.vnet.infrastructure_subnets)[0]
}

resource "terraform_data" "inventory" {
  count = var.infrastructure_controller_count
  connection {
    type = "ssh"
    user = var.infrastructure_admin_username
    host = module.controller[count.index].vm_public_ip
    private_key = file(var.infrastructure_admin_ssh_private_key_filepath)
    agent    = false
    timeout  = "10m"
  }

  provisioner "file" {
      content = templatefile("${path.module}/templates/inventory.j2", { 
        aap_controller_hosts = module.controller[*].nic_private_ip
        aap_ee_hosts = module.execution[*].nic_private_ip
        aap_hub_hosts = module.hub[*].nic_private_ip
        aap_eda_hosts = module.eda[*].nic_private_ip
        aap_eda_allowed_hostnames = module.eda[*].vm_public_ip
        infrastructure_db_username = var.infrastructure_db_username
        infrastructure_db_password = var.infrastructure_db_password
        aap_red_hat_username = var.aap_red_hat_username
        aap_red_hat_password= var.aap_red_hat_password
        aap_db_host = module.db.postgresql_flexible_fqdn
        aap_admin_password = var.aap_admin_password
        infrastructure_admin_username = var.infrastructure_admin_username
      })
      destination = var.infrastructure_aap_installer_inventory_path
  }
}

