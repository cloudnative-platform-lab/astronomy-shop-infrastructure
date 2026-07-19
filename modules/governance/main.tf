data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  audit_bucket_enabled = var.enable_cloudtrail || var.enable_config
}

data "aws_iam_policy_document" "audit_kms" {
  count = local.audit_bucket_enabled ? 1 : 0

  statement {
    sid       = "EnableAccountAdministration"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid = "AllowAuditServices"
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com", "config.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_kms_key" "audit" {
  count = local.audit_bucket_enabled ? 1 : 0

  description             = "${var.name}-${var.environment} audit evidence encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.audit_kms[0].json
  tags                    = var.tags
}

resource "aws_kms_alias" "audit" {
  count = local.audit_bucket_enabled ? 1 : 0

  name          = "alias/${var.name}-${var.environment}-audit"
  target_key_id = aws_kms_key.audit[0].key_id
}

resource "aws_s3_bucket" "audit" {
  count = local.audit_bucket_enabled ? 1 : 0

  bucket = "${var.name}-${var.environment}-${data.aws_caller_identity.current.account_id}-audit"
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "audit" {
  count = local.audit_bucket_enabled ? 1 : 0

  bucket                  = aws_s3_bucket.audit[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "audit" {
  count = local.audit_bucket_enabled ? 1 : 0

  bucket = aws_s3_bucket.audit[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit" {
  count = local.audit_bucket_enabled ? 1 : 0

  bucket = aws_s3_bucket.audit[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.audit[0].arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "audit" {
  count = local.audit_bucket_enabled ? 1 : 0

  bucket = aws_s3_bucket.audit[0].id

  rule {
    id     = "audit-retention"
    status = "Enabled"

    filter { prefix = "" }

    expiration {
      days = var.audit_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.audit_retention_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.audit]
}

resource "aws_s3_bucket_policy" "audit" {
  count = local.audit_bucket_enabled ? 1 : 0

  bucket = aws_s3_bucket.audit[0].id
  policy = data.aws_iam_policy_document.audit_bucket[0].json
}

data "aws_iam_policy_document" "audit_bucket" {
  count = local.audit_bucket_enabled ? 1 : 0

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.audit[0].arn,
      "${aws_s3_bucket.audit[0].arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid = "AWSCloudTrailAclCheck"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.audit[0].arn]
  }

  statement {
    sid = "AWSCloudTrailWrite"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.audit[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid = "AWSConfigAclCheck"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.audit[0].arn]
  }

  statement {
    sid = "AWSConfigWrite"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.audit[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_cloudtrail" "this" {
  count = var.enable_cloudtrail ? 1 : 0

  name                          = "${var.name}-${var.environment}-audit"
  s3_bucket_name                = aws_s3_bucket.audit[0].bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.audit[0].arn
  tags                          = var.tags

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [aws_s3_bucket_policy.audit]
}

resource "aws_iam_role" "config" {
  count = var.enable_config ? 1 : 0

  name = "${var.name}-${var.environment}-aws-config"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "config.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config" {
  count = var.enable_config ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "this" {
  count = var.enable_config ? 1 : 0

  name     = "${var.name}-${var.environment}"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [aws_iam_role_policy_attachment.config]
}

resource "aws_config_delivery_channel" "this" {
  count = var.enable_config ? 1 : 0

  name           = "${var.name}-${var.environment}"
  s3_bucket_name = aws_s3_bucket.audit[0].bucket

  snapshot_delivery_properties {
    delivery_frequency = "TwentyFour_Hours"
  }

  depends_on = [
    aws_config_configuration_recorder.this,
    aws_s3_bucket_policy.audit
  ]
}

resource "aws_config_configuration_recorder_status" "this" {
  count = var.enable_config ? 1 : 0

  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}
