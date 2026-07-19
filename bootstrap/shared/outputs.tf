output "ecr_repository_urls" {
  description = "Shared ECR repository URL for every Astronomy Shop service."
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "Shared ECR repository ARNs used by the GitHub Actions role."
  value       = module.ecr.repository_arns
}

output "github_actions_role_arn" {
  description = "Set this as the AWS_ROLE_ARN GitHub Actions repository variable."
  value       = module.cicd.github_actions_role_arn
}

output "github_oidc_provider_arn" {
  value = module.cicd.github_oidc_provider_arn
}
