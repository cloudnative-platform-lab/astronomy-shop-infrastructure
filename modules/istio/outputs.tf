output "namespace" {
  value = var.enabled ? var.namespace : null
}

output "injection_enabled_namespace" {
  value = var.enabled ? var.application_namespace : null
}
