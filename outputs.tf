output "deployment_id" {
  description = "Print Deployment ID"
  value = var.deployment_id == "" ? random_string.deployment_id[0].id : var.deployment_id
}
output "vnet_outputs" {
  description = "vnet outputs"
  value = module.vnet
}
output "db_outputs" {
  description = "db outputs"
  value = module.db
}
output "controller_vm_module_outputs" {
  description = "VM outputs"
  value = module.controller
}

output "hub_vm_module_outputs" {
  description = "VM outputs"
  value = module.hub
}
output "execution_vm_module_outputs" {
  description = "VM outputs"
  value = module.execution
}

output "eda_vm_module_outputs" {
  description = "VM outputs"
  value = module.eda
}