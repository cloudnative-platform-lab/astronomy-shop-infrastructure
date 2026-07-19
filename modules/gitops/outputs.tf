output "argocd_namespace" {
  description = "Namespace where Argo CD is installed."
  value       = local.argocd_namespace
}

output "argocd_release_name" {
  description = "Name of the Argo CD Helm release."
  value       = try(helm_release.argocd[0].name, null)
}

output "root_application_name" {
  description = "Root Argo CD Application created by Terraform."
  value       = try(kubernetes_manifest.root_application[0].manifest.metadata.name, null)
}

output "root_application_path" {
  description = "Git path watched by the root Argo CD Application."
  value       = local.root_application_path
}
