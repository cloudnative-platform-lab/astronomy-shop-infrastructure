data "aws_caller_identity" "current" {}

resource "aws_kms_key" "replica" {
  count = var.enable_replica_bucket ? 1 : 0

  description             = "${var.name}-${var.environment} disaster recovery encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "replica" {
  count = var.enable_replica_bucket ? 1 : 0

  name          = "alias/${var.name}-${var.environment}-dr"
  target_key_id = aws_kms_key.replica[0].key_id
}

resource "aws_s3_bucket" "replica" {
  count = var.enable_replica_bucket ? 1 : 0

  bucket = "${var.name}-${var.environment}-${data.aws_caller_identity.current.account_id}-dr-replica"
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "replica" {
  count = var.enable_replica_bucket ? 1 : 0

  bucket                  = aws_s3_bucket.replica[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "replica" {
  count = var.enable_replica_bucket ? 1 : 0

  bucket = aws_s3_bucket.replica[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  count = var.enable_replica_bucket ? 1 : 0

  bucket = aws_s3_bucket.replica[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.replica[0].arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "replica" {
  count = var.enable_replica_bucket ? 1 : 0

  bucket = aws_s3_bucket.replica[0].id

  rule {
    id     = "expire-old-replica-versions"
    status = "Enabled"

    filter { prefix = "" }

    noncurrent_version_expiration {
      noncurrent_days = var.replica_noncurrent_version_retention_days
    }
  }
}

resource "aws_backup_vault" "replica" {
  count = var.enable_replica_bucket ? 1 : 0

  name        = "${var.name}-${var.environment}-dr-backup-vault"
  kms_key_arn = aws_kms_key.replica[0].arn
  tags        = var.tags
}
