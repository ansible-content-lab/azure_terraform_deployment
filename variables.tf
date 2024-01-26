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

variable "deployment_id" {
  description = "Creates a random string that will be used in tagging for correlating the resources used with a deployment of AAP."
  type = string
  validation {
    condition = ((length(var.deployment_id) >= 2 && length(var.deployment_id)<=10) || length(var.deployment_id) == 0) && (can(regex("^[a-z]", var.deployment_id)) || var.deployment_id == "")
    error_message = "deployment_id length should be between 2-10 chars and should contain lower case alpha chars only"
  }
}

variable "infrastructure_admin_username" {
  type = string
  default = "azureuser"
  description = "The admin username of the VM that will be deployed."
  nullable = false
}

variable "infrastructure_db_username" {
  description = "PostgreSQL username."
  type = string
  default = "psqladmin"
}

variable "infrastructure_db_password" {
  description = "PostgreSQL password."
  type = string
  sensitive = true
}

variable "infrastructure_db_engine_version" {
  description = "PostgreSQL DB version."
  type = string
  default = "13"
}

variable "infrastructure_db_storage_mb" {
  description = "PostgreSQL DB storage in MB."
  type = number
  default = 32768
}

variable "infrastructure_db_instance_sku" {
  description = "PostgreSQL DB instance SKU name."
  type = string
  default = "GP_Standard_D2s_v3"
}

variable "infrastructure_controller_count" {
  description = "The number of instances for controller"
  type = number
  default = 1
}

variable "infrastructure_controller_instance_type" {
  description = "The SKU which should be used for controller Virtual Machine, such as `Standard_B4ms`."
  type = string
  default = "Standard_B4ms"
}

variable "infrastructure_eda_count" {
  description = "The number of EDA instances"
  type = number
  default = 0
}
variable "infrastructure_eda_instance_type" {
  description = "The SKU which should be used for eda Virtual Machine, such as `Standard_B4ms`."
  type = string
  default = "Standard_B4ms"
}
variable "infrastructure_execution_count" {
  description = "The number of execution instances"
  type = number
  default = 0
}
variable "infrastructure_execution_instance_type" {
  description = "The SKU which should be used for execution Virtual Machine, such as `Standard_B4ms`."
  type = string
  default = "Standard_B4ms"
}

variable "infrastructure_hub_count" {
  description = "The number of instances for hub"
  type = number
  default = 1
}
variable "infrastructure_hub_instance_type" {
  description = "The SKU which should be used for hub Virtual Machine, such as `Standard_B4ms`."
  type = string
  default = "Standard_B4ms"
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
variable "aap_red_hat_username" {
  description = "Red Hat account name that will be used for Subscription Management."
  type = string
}

variable "aap_red_hat_password" {
  description = "Red Hat account password."
  type = string
  sensitive = true
}

variable "aap_admin_password" {
  description = "The admin password to create for Ansible Automation Platform application."
  type = string
  sensitive = true
}

variable "infrastructure_aap_installer_inventory_path" {
  description = "Inventory path on the installer host"
  default = "/home/azureuser/inventory_azure"
  type = string
}

