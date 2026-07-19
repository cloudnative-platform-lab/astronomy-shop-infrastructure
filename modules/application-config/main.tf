resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = var.secret_arn
  secret_string = jsonencode(var.config)
}
