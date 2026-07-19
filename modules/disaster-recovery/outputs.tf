output "replica_bucket_name" { value = try(aws_s3_bucket.replica[0].bucket, null) }
output "replica_bucket_arn" { value = try(aws_s3_bucket.replica[0].arn, null) }
output "replica_kms_key_arn" { value = try(aws_kms_key.replica[0].arn, null) }
output "backup_vault_arn" { value = try(aws_backup_vault.replica[0].arn, null) }
