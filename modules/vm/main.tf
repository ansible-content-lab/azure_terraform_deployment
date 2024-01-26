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

resource "random_string" "infrastructure_vm_deployment_id" {
  length = 8
  special = false
  upper = false
  numeric = false
}

# Create public IP
resource "azurerm_public_ip" "aap_infrastructure_public_ip" {
  depends_on = [ random_string.infrastructure_vm_deployment_id ]
  name = "pip-${var.deployment_id}-${var.app_tag}-${random_string.infrastructure_vm_deployment_id.id}"
  resource_group_name = var.resource_group
  location = var.location
  allocation_method = "Static"
}

# Create network interface
resource "azurerm_network_interface" "aap_infrastructure_network_interface" {
  name = "nic-${var.deployment_id}-${var.app_tag}-${random_string.infrastructure_vm_deployment_id.id}"
  resource_group_name = var.resource_group
  location = var.location

  ip_configuration {
    name = azurerm_public_ip.aap_infrastructure_public_ip.name
    subnet_id = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.aap_infrastructure_public_ip.id
  }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "aap_infrastructure_vm" {
  depends_on = [ random_string.infrastructure_vm_deployment_id ]

  name = "vm-${var.deployment_id}-${var.app_tag}-${random_string.infrastructure_vm_deployment_id.id}"
  resource_group_name = var.resource_group
  location = var.location
  network_interface_ids = [azurerm_network_interface.aap_infrastructure_network_interface.id]
  size = var.infrastructure_instance_type
  os_disk {
    name = "vm-${var.deployment_id}-${var.app_tag}-${random_string.infrastructure_vm_deployment_id.id}"
    caching = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb = var.os_disk.disk_size_gb
  }
  source_image_reference {
    offer = var.source_image_reference.offer
    publisher = var.source_image_reference.publisher
    sku = var.source_image_reference.sku
    version = var.source_image_reference.version
  }
  plan {
    product = var.infrastructure_plan.product
    publisher = var.infrastructure_plan.publisher
    name = var.infrastructure_plan.name
  }
  admin_ssh_key {
    username = var.infrastructure_admin_username
    public_key = file(var.infrastructure_admin_ssh_public_key_filepath)
  }

  disable_password_authentication = true
  admin_username = var.infrastructure_admin_username

  tags = merge(
    {
      Name = "vm-${var.deployment_id}-${var.app_tag}-${random_string.infrastructure_vm_deployment_id.id}"
      app = var.app_tag
    },
    var.persistent_tags
  )
  }

# Copy SSH private key file to controller vm's to connect to other servers
resource "terraform_data" "aap_infrastructure_sshkey" {
  depends_on = [  azurerm_linux_virtual_machine.aap_infrastructure_vm ]

  count = var.app_tag == "controller" ? 1: 0
  triggers_replace = [
    azurerm_linux_virtual_machine.aap_infrastructure_vm.id
  ]
  connection {
      type = "ssh"
      user = var.infrastructure_admin_username
      host = azurerm_public_ip.aap_infrastructure_public_ip.ip_address
      private_key = file(var.infrastructure_admin_ssh_private_key_filepath)
  }
  provisioner "file" {
    source = var.infrastructure_admin_ssh_private_key_filepath
    destination = "/home/${var.infrastructure_admin_username}/.ssh/infrastructure_ssh_private_key.pem"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod 0600 /home/${var.infrastructure_admin_username}/.ssh/infrastructure_ssh_private_key.pem",
    ]
  }
}

resource "terraform_data" "aap_subscription_manager" {
  depends_on = [ azurerm_linux_virtual_machine.aap_infrastructure_vm ]

  triggers_replace = [
    azurerm_linux_virtual_machine.aap_infrastructure_vm.id
  ]
  connection {
    type = "ssh"
    user = var.infrastructure_admin_username
    host = azurerm_public_ip.aap_infrastructure_public_ip.ip_address
    private_key = file(var.infrastructure_admin_ssh_private_key_filepath)
    timeout = "10m"
  }
  provisioner "remote-exec" {
    inline = [ 
      "sudo subscription-manager register --username ${var.aap_red_hat_username} --password ${var.aap_red_hat_password} --auto-attach",
      "sudo subscription-manager config --rhsm.manage_repos=1",
      "yes | sudo dnf upgrade"
      ]
  }
}
