output "postgresql_flexible_fqdn" {
  description = "FQDN of the PostgreSQL server."
  value       = azurerm_postgresql_flexible_server.aap.fqdn
}