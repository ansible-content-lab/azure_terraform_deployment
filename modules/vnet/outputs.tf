output "aap_private_dns_zone_id" {
  description = "Private dns zone id"
  value = azurerm_private_dns_zone.aap_private_dns_zone.id
}

output "aap_infrastructure_postgres_subnet_id" {
  description = "Private postgres subnet id"
  value = azurerm_subnet.aap_infrastructure_postgres_subnet.id
}

output "infrastructure_subnets" {
  description = "List of subnets"
  value = {
    for key, subnet in azurerm_subnet.aap_infrastructure_subnets : key => subnet.id
  }

  depends_on = [azurerm_subnet.aap_infrastructure_subnets]
}