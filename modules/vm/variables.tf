variable "deployment_id" {
  description = "Creates a random string that will be used in tagging for correlating the resources used with a deployment of AAP."
  type    = string
  validation {
    condition = (length(var.deployment_id) == 8 || length(var.deployment_id) == 0) && (can(regex("^[a-z]", var.deployment_id)) || var.deployment_id == "")
    error_message = "deployment_id length should be 8 chars and should contain lower case alpha chars only"
  }
}
variable "resource_group" {
  description = "Azure resource group."
  type = string
  default = "aap_on_azure"
}

variable "location" {
  description = "Azure location."
  type = string
  default = "East US"
}
variable "app_tag" {
  description = "AAP tag used in VM name."
  type = string
}
variable persistent_tags {
  description = "Persistent tags"
  type = map(string)
}
variable "source_image_reference" {
  type = object({
    publisher = string
    offer = string
    sku = string
    version = string
  })
  default = {
    publisher = "redhat"
    offer = "rh-ansible-self-managed"
    sku = "rh-aap2"
    version = "latest"
  }
  description = <<-EOT
  object({
    publisher = "(Required) Specifies the publisher of the image used to create the virtual machines."
    offer = "(Required) Specifies the offer of the image used to create the virtual machines."
    sku = "(Required) Specifies the SKU of the image used to create the virtual machines."
    version = "(Required) Specifies the version of the image used to create the virtual machines."
  })
  EOT
}

variable "infrastructure_plan" {
   type = object({
    product = string
    publisher = string
    name = string
  })
  default = {
    product = "rh-ansible-self-managed"
    publisher = "redhat"
    name = "rh-aap2"
  }
  description = <<-EOT
  object({
    product = "Specifies the product name for the image used to create the virtual machines."
    publisher = "Specifies the publisher of the image used to create the virtual machines."
    name = "(Required) Specifies the name of the image used to create the virtual machines."
  })
  EOT
}
variable "os_disk" {
  type = object({
    caching = string
    storage_account_type = string
    disk_size_gb = optional(number)
  })
  default = {
    caching = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb = 100
  }
  description = <<-EOT
  object({
    caching = "(Required) The Type of Caching which should be used for the Internal OS Disk. Possible values are `None`, `ReadOnly` and `ReadWrite`."
    storage_account_type = "(Required) The Type of Storage Account which should back this the Internal OS Disk. Possible values are `Standard_LRS`, `StandardSSD_LRS`, `Premium_LRS`, `StandardSSD_ZRS` and `Premium_ZRS`."
    disk_size_gb = "(Optional) The Size of the Internal OS Disk in GB, if you wish to vary from the size used in the image this Virtual Machine is sourced from. If specified this must be equal to or larger than the size of the Image the Virtual Machine is based on. When creating a larger disk than exists in the image you'll need to repartition the disk to use the remaining space."
  })
  EOT
  nullable = false
}

variable "infrastructure_admin_username" {
  type = string
  description = "The admin username of the VM that will be deployed."
  nullable = false
}

variable "infrastructure_virtual_machines" {
  type = map(object({
    name = string
    subnet = string
    instance_type = string
  }))
  default = {
  "controller" = {
    instance_type = "Standard_B4ms"
    name = "controller"
    subnet = "controller-eda-hub"
  },
  "execution" = {
    instance_type = "Standard_B4ms"
    name = "execution"
    subnet = "execution"
  },
  "hub" = {
    instance_type = "Standard_B4ms"
    name = "hub"
    subnet = "controller-eda-hub"
  },
  "eda" = {
    instance_type = "Standard_B4ms"
    name = "eda"
    subnet = "controller-eda-hub"
  }
}
  description = <<-EOT
  object({
    name = "The app name to use in virtual machine name."
    number_of_instances = "The number of instances to be created."
    subnet = "The subnet name."
    instance_type = "The SKU which should be used for this Virtual Machine, such as `Standard_B4ms`."
  })
  EOT
}
variable "subnet_id" {
  description = "Azure subnet id."
  type = string
}

variable "infrastructure_admin_ssh_public_key_filepath" {
  description = "Public ssh key file path."
  type = string
  default = "~/.ssh/id_rsa.pub"
}

variable "infrastructure_admin_ssh_private_key_filepath" {
  description = "Private ssh key file path."
  type = string
  default = "~/.ssh/id_rsa"
}
