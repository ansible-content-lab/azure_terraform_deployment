# azure_terraform_deployment

This is the template that will deploy Ansible on Azure. While this template will work with any Ansible deployment on Azure, this is intended to be a starting point for customers that purchase Ansible Automation Platform subscriptions from the Azure marketplace. Take this template and enhance/improve/update based on the resources that you need for your AAP deployment.

## Introduction

This template performs the following actions in the order listed.

| Step | Description |
| ---- | ----------- |
| Create a deployment ID | Creates a random string that will be used in tagging for correlating the resources used with a deployment of AAP. |
| Create a resource group | Creates a resource group to contain all of the related resources for the AAP installation. |
| Create a virtual network | Creates a virtual network with a CIDR block that can contain the subnets that will be created. |
| Create subnets | Creates the subnets for automation controller, execution environments, private automation hub, and Event-Driven Ansible. |
| Create the private DNS zone | Creates the private DNS zone for PostgreSQL. |
| Create a network security group | Creates a security group that allows AAP ports within the VNET and HTTPS and automation mesh ports externally. |
| Create a database server | Creates a PostgreSQL Flexible Server and the necessary databases inside of it for the controller, hub, and Event-Driven Ansible components. |
| Create the controller VMs | Creates VMs for controller, a public IP, and the virtual network interface card with the public IP attached. |
| Create the execution nodes VMs | Creates VMs for execution nodes (if enabled), a public IP, and the virtual network interface card with the public IP attached. |
| Create the hub VMs | Creates VMs for private automation hub, a public IP, and the virtual network interface card with the public IP attached. |
| Create the Event-Driven Ansible VMs | Creates VMs for Event-Driven Ansible (if enabled), a public IP, and the virtual network interface card with the public IP attached. |
| Register the VMs with Red Hat | Uses RHEL subscription manager to register each virtual machine for required RPM repos. |
| Update the VMs | Updates each VM deployed with latest kernel and packages. |
| Setup one controller VM as the installer | Configures the installer VMs with a private SSH key so that it can communicate with the other VMs that are part of the installation process and configures the installer inventory file based on the VMs that were created as part of this process. |

## Getting Started

This section will walk through deploying the Azure infrastructure and Ansible Automation Platform.

You may also download the this repository from GitHub and modify to suit your needs.

### Azure Credentials

The Azure collection used as a dependency requires Azure credentials, which can be set in different places, such as the `~/.azure/credentials` file above, through environment variables, or the Azure CLI profile.
The easiest, and most portable, approach will be to set the following env vars.

- `AZURE_CLIENT_ID`
- `AZURE_SECRET`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_TENANT`

This template will need a way to connect to the virtual machines that it creates.
By default, VMs are created with public IP addresses to make this simple, but the template may be modified to use private IP addresses if your local machine can route traffic to private networks.

## Deploying Ansible Automation Platform

This section will walk through deploying the Azure infrastructure and Ansible Automation Platform.

### Checklist

- [ ] Download this repository
- [ ] Terraform installed locally (`terraform`)
- [ ] Configure the Azure environment variables for authentication
- [ ] Ensure you don't have anything else in the resource group that you use (default of specified via an extra var)

### Deploying infrastructure

The variables below are required for running this template

| Variable | Description |
| -------- | ----------- |
| `aap_red_hat_username` | This is your Red Hat account name that will be used for Subscription Management (https://access.redhat.com/management). |
| `aap_red_hat_password` | The Red Hat account password. |
| `infrastructure_db_username` | Username that will be the admin of the new database server. |
| `infrastructure_db_password` | Password of the admin of the new database server. |
| `aap_admin_password` | The admin password to create for Ansible Automation Platform application. |

Additional variables can be found in variables.tf, modules/db/variables.tf , modules/vm/variables.tf, modules/vnet/variables.tf

Assuming that all variables are configured properly and your Azure account has permissions to deploy the resources defined in this template.

Initialize Terraform

```bash
terraform init -upgrade
```

Validate configuration
```bash
terraform validate
```

Check the plan

```bash
terraform plan -out=test-plan.tfplan
```

Apply infrastructure

```bash
terraform apply -var infrastructure_db_password=<db-password> -var aap_admin_password=<aap-admin-password> -var aap_red_hat_username=<redhat-username> -var aap_red_hat_password=<redhat-password>
```
Confirm to create infrastructure or pass in the `-auto-approve` parameter.

### Installing Red Hat Ansible Automation Platform

At this point you can ssh into one of the controller nodes and run the installer. The example below assumes the default variables.tf values for `infrastructure_admin_username` and `infrastructure_admin_ssh_private_key_filepath`. 

```bash
ssh -i ~/.ssh/id_rsa azureuser@<controller-public-ip> 
```

We provided a sample inventory that could be used to deploy AAP.
You might need to edit the inventory to fit your needs.

Before you start the installation, you need to attach Ansible Automation Platform to the system where you're running the installer. 

Find the pool id for Ansible Automation Platform subscription using command 
```bash
sudo subscription-manager list --all --available
```

Attach subscription to all the VMs 
```bash
sudo subscription-manager attach --pool=<pool-id>
```

Run the installer to deploy Ansible Automation Platform
```bash
$ cd /opt/ansible-automation-platform/installer/
$ sudo ./setup.sh -i inventory_azure
```

For more information, read the install guide from https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/

## Uninstall

This will permanently remove all data and infrastructure in the resource group, so only run this playbook if you are sure that you want to delete all traces of the deployment.

```bash
terraform destroy
```
Confirm to destroy infrastructure or pass in the `-auto-approve` parameter.

## Linting Terraform

We recommend using [tflint](https://github.com/terraform-linters/tflint) to help with maintaining  terraform syntax and standards.

### Initialize
```bash
tflint --init
```
### Running tflint
```bash
tflint --recursive
```
