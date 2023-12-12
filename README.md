# azure_terraform_deployment

This is the template that will deploy Ansible on Azure. While this template will work with any Ansible deployment on Azure, this is intended to be a starting point for customers that purchase Ansible Automation Platform subscriptions from the Azure marketplace. Take this template and enhance/improve/update based on the resources that you need for your AAP deployment.

## Deploying Ansible Automation Platform

This section will walk through deploying the Azure infrastructure and Ansible Automation Platform.

### Deploying Infrastructure

Initialize Terraform

```bash
terraform init
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
terraform apply
```
Confirm to create infrastructure or pass in the `-auto-approve` parameter.


To destroy infrastructure

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
