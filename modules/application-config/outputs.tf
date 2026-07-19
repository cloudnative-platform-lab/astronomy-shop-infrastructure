output "version_id" {
  value     = aws_secretsmanager_secret_version.this.version_id
  sensitive = true
}
