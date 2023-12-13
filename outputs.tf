output "deployment_id" {
  description = "Print Deployment ID"
  value = var.deployment_id == "" ? random_string.deployment_id[0].id : var.deployment_id
}
output "vm_module_outputs" {
  description = "VM outputs"
  value = module.controller
}
