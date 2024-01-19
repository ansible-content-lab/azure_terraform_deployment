variable "deployment_id" {
  description = "Creates a random string that will be used in tagging for correlating the resources used with a deployment of AAP."
  type = string
  validation {
    condition = length(var.deployment_id) == 8 && can(regex("^[a-z]", var.deployment_id))
    error_message = "deployment_id length should be 8 chars and should contain lower case alphabets only"
  }
}

variable persistent_tags {
  description = "Persistent tags"
  type = map(string)
}

variable "resource_group" {
  description = "Azure resource group."
  type = string
}

variable "location" {
  description = "Azure location."
  type = string
}

variable "infrastructure_vpc_cidr" {
  description = "IPv4 CIDR netmask for the VPC resource."
  type = string
  default = "172.16.0.0/22"
}

variable "infrastructure_vpc_subnets" {
  type = list(object({
    name = string
    cidr_block = string
  }))
  default = [{
    name = "controller-eda-hub"
    cidr_block = "172.16.0.0/24"
  },
   {
    name = "execution"
    cidr_block = "172.16.1.0/24"
  },
  {
    name = "appgw"
    cidr_block = "172.16.3.0/24"
  }]
}


variable "infrastructure_vpc_postgres_subnet" {
  type = object({
    name = string
    cidr_block = string
    delegations = list(object({
      serviceName = string
      name = string
    }))
  })
   default = {
    name = "postgres"
    cidr_block = "172.16.2.0/24"
    delegations = [ {
      serviceName = "Microsoft.DBforPostgreSQL/flexibleServers"
      name = "subnet-postgres-delegation"
    } ]
  }
}