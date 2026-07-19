resource "aws_kms_key" "platform" {
  description             = "${var.name}-${var.environment} platform encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "platform" {
  name          = "alias/${var.name}-${var.environment}-platform"
  target_key_id = aws_kms_key.platform.key_id
}

resource "aws_guardduty_detector" "this" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true
  tags   = var.tags
}

resource "aws_securityhub_account" "this" {
  count = var.enable_security_hub ? 1 : 0
}

resource "aws_inspector2_enabler" "this" {
  count          = var.enable_inspector ? 1 : 0
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["ECR", "EC2", "LAMBDA"]
}

resource "aws_secretsmanager_secret" "app_config" {
  name                    = "${var.name}/${var.environment}/app-config"
  kms_key_id              = aws_kms_key.platform.arn
  recovery_window_in_days = var.environment == "prod" ? 30 : 0
  tags                    = var.tags
}

data "aws_caller_identity" "current" {}

