output "managed_namespaces" { value = keys(kubernetes_namespace_v1.managed) }
output "falco_enabled" { value = var.enable_falco }
output "falco_release_name" { value = var.enable_falco ? helm_release.falco[0].name : null }
output "kyverno_enabled" { value = var.enable_kyverno || var.enable_signed_image_policy }
output "signed_image_policy_enabled" { value = var.enable_signed_image_policy }
