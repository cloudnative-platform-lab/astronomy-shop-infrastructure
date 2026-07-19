output "namespace" { value = var.namespace }
output "service_accounts" { value = keys(kubernetes_service_account_v1.service) }
output "external_secrets_role_arn" { value = try(aws_iam_role.external_secrets[0].arn, null) }
output "external_secret_target_name" { value = local.external_secrets_integration_enabled ? var.external_secret_target_name : null }
output "database_secret_target_name" { value = local.external_secrets_integration_enabled && length(var.external_secret_arns) > 1 ? var.database_secret_target_name : null }
output "app_storage_role_arn" { value = try(aws_iam_role.app_storage[0].arn, null) }
