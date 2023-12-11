terraform {
  required_version = ">= 1.5.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.83.0"
    }
  }
}

resource "azurerm_postgresql_flexible_server" "aap" {
  name                   = "${var.deployment_id}-psqlflexibleserver"
  resource_group_name    = var.resource_group
  location               = var.location
  version                = var.infrastructure_db_engine_version
  delegated_subnet_id    = var.subnet_id
  private_dns_zone_id    = var.private_dns_zone_id
  administrator_login    = var.infrastructure_db_username
  administrator_password = var.infrastructure_db_password

  storage_mb = var.infrastructure_db_storage_mb

  sku_name   = var.infrastructure_db_instance_sku
  #depends_on = [azurerm_private_dns_zone_virtual_network_link.aap]
}

resource "azurerm_postgresql_flexible_server_configuration" "aap" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.aap.id
  value     = "hstore"
}

resource "azurerm_postgresql_flexible_server_database" "awx" {
  name      = "awx"
  server_id = azurerm_postgresql_flexible_server.aap.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_database" "hub" {
  name      = "hub"
  server_id = azurerm_postgresql_flexible_server.aap.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_database" "eda" {
  name      = "eda"
  server_id = azurerm_postgresql_flexible_server.aap.id
  collation = "en_US.utf8"
  charset   = "utf8"
}
