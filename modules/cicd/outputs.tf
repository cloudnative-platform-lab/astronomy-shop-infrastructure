output "github_actions_role_arn" { value = aws_iam_role.github_actions.arn }
output "github_oidc_provider_arn" { value = local.github_oidc_provider_arn }
