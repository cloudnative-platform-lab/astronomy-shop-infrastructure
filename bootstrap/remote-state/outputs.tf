output "state_bucket_name" {
  value = aws_s3_bucket.state.bucket
}

output "lock_table_name" {
  value = try(aws_dynamodb_table.locks[0].name, null)
}

output "state_kms_key_arn" {
  value = try(aws_kms_key.state[0].arn, null)
}

output "backend_config_example" {
  value = {
    bucket       = aws_s3_bucket.state.bucket
    region       = var.aws_region
    use_lockfile = true
  }
}


