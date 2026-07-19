output "namespace" { value = var.namespace }
output "helm_release_name" { value = try(helm_release.this[0].name, null) }
output "dashboard_enabled" { value = var.enable_dashboard }
