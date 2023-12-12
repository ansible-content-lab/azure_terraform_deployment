output "network_interface_private_ip" {
  description = "Private ip address of the vm nic"
  value = azurerm_network_interface.aap_infrastructure_network_interface.private_ip_address
}

output "vm_public_ip" {
  description = "Public ip address of the vm"
  value = azurerm_public_ip.aap_infrastructure_public_ip.ip_address
}
