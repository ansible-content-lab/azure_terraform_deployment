variable "deployment_id" {
  description = "Creates a random string that will be used in tagging for correlating the resources used with a deployment of AAP."
  type    = string
  validation {
    condition     = (length(var.deployment_id) == 8 || length(var.deployment_id) == 0) && (can(regex("^[a-z]", var.deployment_id)) || var.deployment_id == "")
    error_message = "deployment_id length should be 8 chars and should contain lower case alpha chars only"
  }
}

variable "infrastructure_vpc_cidr" {
  description = <<-EOT
    IPv4 CIDR netmask for the VPC resource.
  EOT
  type        = string
  default     = "172.16.0.0/22"
}