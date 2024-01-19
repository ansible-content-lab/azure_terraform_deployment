terraform {
  required_version = ">= 1.5.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.83.0"
    }
  }
}

resource "azurerm_virtual_network" "aap_infrastructure_vnet" {
  name = "vnet-${var.deployment_id}-aap"
  location = var.location
  resource_group_name = var.resource_group
  address_space = [var.infrastructure_vpc_cidr]
  tags = var.persistent_tags
}

resource "azurerm_subnet" "aap_infrastructure_subnets" {
  count = length(var.infrastructure_vpc_subnets)
  name = "subnet-${var.deployment_id}-${var.infrastructure_vpc_subnets[count.index]["name"]}"
  resource_group_name = var.resource_group
  virtual_network_name = azurerm_virtual_network.aap_infrastructure_vnet.name
  address_prefixes = [var.infrastructure_vpc_subnets[count.index]["cidr_block"]]

  depends_on = [ azurerm_virtual_network.aap_infrastructure_vnet ]
}

resource "azurerm_subnet" "aap_infrastructure_postgres_subnet" {
  name = "subnet-${var.deployment_id}-postgres"
  resource_group_name = var.resource_group
  virtual_network_name = azurerm_virtual_network.aap_infrastructure_vnet.name
  address_prefixes = [var.infrastructure_vpc_postgres_subnet["cidr_block"]]
  service_endpoints = ["Microsoft.Storage"]
  delegation {
    name = var.infrastructure_vpc_postgres_subnet["delegations"][0]["name"]
    service_delegation {
      name = var.infrastructure_vpc_postgres_subnet["delegations"][0]["serviceName"]
    }
  }
  depends_on = [ azurerm_virtual_network.aap_infrastructure_vnet ]
}

resource "azurerm_private_dns_zone" "aap_private_dns_zone" {
  name = "aap.${var.deployment_id}.postgres.database.azure.com"
  resource_group_name = var.resource_group
  tags = var.persistent_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres_link" {
  name = "postgres-link"
  private_dns_zone_name = azurerm_private_dns_zone.aap_private_dns_zone.name
  virtual_network_id = azurerm_virtual_network.aap_infrastructure_vnet.id
  resource_group_name = var.resource_group
  tags = var.persistent_tags

  depends_on = [ azurerm_virtual_network.aap_infrastructure_vnet ]
}