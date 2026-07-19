data "aws_region" "current" {}
data "aws_iam_openid_connect_provider" "this" {
  arn = var.oidc_provider_arn
}

locals {
  bucket_name   = coalesce(var.bucket_name, "${var.name}-${var.environment}-velero-backups")
  oidc_provider = replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")
}

resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy_bucket
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = var.kms_key_arn == null ? "AES256" : "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.backup_retention_days
    }
  }
}

resource "aws_iam_role" "this" {
  name = "${var.name}-${var.environment}-velero"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider}:sub" = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
            "${local.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "this" {
  name = "${var.name}-${var.environment}-velero"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = "${aws_s3_bucket.this.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.this.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "helm_release" "this" {
  name             = "velero"
  repository       = "https://vmware-tanzu.github.io/helm-charts"
  chart            = "velero"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  wait             = true

  values = [
    yamlencode({
      credentials = {
        useSecret = false
      }
      serviceAccount = {
        server = {
          name = var.service_account_name
          annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
          }
        }
      }
      initContainers = [
        {
          name  = "velero-plugin-for-aws"
          image = var.aws_plugin_image
          volumeMounts = [
            {
              mountPath = "/target"
              name      = "plugins"
            }
          ]
        }
      ]
      configuration = {
        backupStorageLocation = [
          {
            name     = "default"
            provider = "aws"
            bucket   = aws_s3_bucket.this.bucket
            config = {
              region = data.aws_region.current.name
            }
          }
        ]
        volumeSnapshotLocation = [
          {
            name     = "default"
            provider = "aws"
            config = {
              region = data.aws_region.current.name
            }
          }
        ]
      }
      schedules = var.create_default_schedule ? {
        cluster-daily = {
          disabled = false
          schedule = var.backup_schedule
          template = {
            ttl                = var.backup_ttl
            includedNamespaces = var.included_namespaces
            excludedNamespaces = var.excluded_namespaces
            snapshotVolumes    = var.snapshot_volumes
          }
        }
      } : {}
    })
  ]

  depends_on = [aws_iam_role_policy_attachment.this]
}
