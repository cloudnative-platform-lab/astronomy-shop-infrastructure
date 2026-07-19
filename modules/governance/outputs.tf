output "cloudtrail_name" { value = try(aws_cloudtrail.this[0].name, null) }
output "audit_bucket_name" { value = try(aws_s3_bucket.audit[0].bucket, null) }
output "audit_kms_key_arn" { value = try(aws_kms_key.audit[0].arn, null) }
