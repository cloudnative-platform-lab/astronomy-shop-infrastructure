output "bucket_name" { value = aws_s3_bucket.this.bucket }
output "bucket_arn" { value = aws_s3_bucket.this.arn }
output "role_arn" { value = aws_iam_role.this.arn }
output "namespace" { value = var.namespace }
output "helm_release_name" { value = helm_release.this.name }
