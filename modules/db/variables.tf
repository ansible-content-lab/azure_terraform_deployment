variable "resource_group" {
  description = "Azure resource group."
  type        = string
  default     = "aap_on_azure"
}

variable "location" {
  description = "Azure location."
  type        = string
  default     = "East US"
}

variable "deployment_id" {
  description = "Creates a random string that will be used in tagging for correlating the resources used with a deployment of AAP."
  type    = string
  validation {
    condition     = (length(var.deployment_id) == 8 || length(var.deployment_id) == 0) && (can(regex("^[a-z]", var.deployment_id)) || var.deployment_id == "")
    error_message = "deployment_id length should be 8 chars and should contain lower case alpha chars only"
  }
}

variable "infrastructure_db_username" {
  description = "PostgreSQL username."
  type        = string
  default     = "psqladmin"
}

variable "infrastructure_db_password" {
  description = "PostgreSQL password."
  type        = string
  default     = "ChangeMe1234"
}

variable "infrastructure_db_engine_version" {
  description = "PostgreSQL DB version."
  type        = string
  default     = "13"
}

variable "infrastructure_db_storage_mb" {
  description = "PostgreSQL DB storage in MB."
  type        = number
  default     = 32768
}

variable "infrastructure_db_instance_sku" {
  description = "PostgreSQL DB instance SKU name."
  type        = string
  default     = "GP_Standard_D2s_v3"
}

variable "subnet_id" {
  description = "Azure subnet id."
  type        = string
}

variable "private_dns_zone_id" {
  description = "Azure private DNS zone id."
  type        = string
}
