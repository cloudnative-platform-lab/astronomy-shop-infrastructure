output "kms_key_arn" { value = aws_kms_key.platform.arn }
output "app_config_secret_arn" { value = aws_secretsmanager_secret.app_config.arn }

