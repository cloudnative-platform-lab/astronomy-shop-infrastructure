resource "aws_backup_vault" "this" {
  name        = "${var.name}-${var.environment}-backup-vault"
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

resource "aws_iam_role" "backup" {
  name = "${var.name}-${var.environment}-aws-backup"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_plan" "this" {
  name = "${var.name}-${var.environment}-backup-plan"

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.this.name
    schedule          = "cron(0 5 ? * * *)"

    lifecycle {
      delete_after = var.daily_retention_days
    }

    dynamic "copy_action" {
      for_each = var.copy_destination_vault_arn == null ? [] : [var.copy_destination_vault_arn]
      content {
        destination_vault_arn = copy_action.value
        lifecycle {
          delete_after = var.weekly_retention_days
        }
      }
    }
  }

  rule {
    rule_name         = "weekly"
    target_vault_name = aws_backup_vault.this.name
    schedule          = "cron(0 6 ? * SUN *)"

    lifecycle {
      delete_after = var.weekly_retention_days
    }
  }

  tags = var.tags
}

resource "aws_backup_selection" "this" {
  count        = length(var.backup_resource_arns) == 0 ? 0 : 1
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${var.name}-${var.environment}-selection"
  plan_id      = aws_backup_plan.this.id
  resources    = var.backup_resource_arns
}
