resource "kubernetes_namespace_v1" "app" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/name"             = var.name
      "app.kubernetes.io/part-of"          = var.name
      "platform.openai.com/env"            = var.environment
      "pod-security.kubernetes.io/enforce" = "baseline"
    }
  }
}

resource "kubernetes_service_account_v1" "service" {
  for_each = toset(var.services)

  metadata {
    name      = each.value
    namespace = var.namespace

    labels = {
      "app.kubernetes.io/name"    = each.value
      "app.kubernetes.io/part-of" = var.name
    }

    annotations = local.app_storage_access_enabled && each.value == var.app_storage_service_account_name ? {
      "eks.amazonaws.com/role-arn" = aws_iam_role.app_storage[0].arn
    } : {}
  }

  depends_on = [kubernetes_namespace_v1.app]
}

locals {
  external_secrets_integration_enabled = var.enable_external_secrets && var.oidc_provider_arn != "" && length(var.external_secret_arns) > 0
  app_storage_access_enabled           = var.oidc_provider_arn != "" && var.app_storage_bucket_arn != ""
  oidc_integration_enabled             = local.external_secrets_integration_enabled || local.app_storage_access_enabled
}

data "aws_iam_openid_connect_provider" "this" {
  count = local.oidc_integration_enabled ? 1 : 0
  arn   = var.oidc_provider_arn
}

locals {
  oidc_provider = local.oidc_integration_enabled ? replace(data.aws_iam_openid_connect_provider.this[0].url, "https://", "") : ""
}

data "aws_iam_policy_document" "app_storage_assume_role" {
  count = local.app_storage_access_enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.app_storage_service_account_name}"]
    }
  }
}

resource "aws_iam_role" "app_storage" {
  count = local.app_storage_access_enabled ? 1 : 0

  name               = "${var.name}-${var.environment}-${var.app_storage_service_account_name}-s3"
  assume_role_policy = data.aws_iam_policy_document.app_storage_assume_role[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy" "app_storage" {
  count = local.app_storage_access_enabled ? 1 : 0

  name = "${var.name}-${var.environment}-app-storage"
  role = aws_iam_role.app_storage[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect   = "Allow"
          Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
          Resource = [var.app_storage_bucket_arn]
        },
        {
          Effect   = "Allow"
          Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
          Resource = ["${var.app_storage_bucket_arn}/*"]
        }
      ],
      var.kms_key_arn == "" ? [] : [
        {
          Effect   = "Allow"
          Action   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
          Resource = [var.kms_key_arn]
        }
      ]
    )
  })
}

data "aws_iam_policy_document" "external_secrets_assume_role" {
  count = local.external_secrets_integration_enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:external-secrets:external-secrets"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  count = local.external_secrets_integration_enabled ? 1 : 0

  name               = "${var.name}-${var.environment}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume_role[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy" "external_secrets" {
  count = local.external_secrets_integration_enabled ? 1 : 0

  name = "${var.name}-${var.environment}-external-secrets"
  role = aws_iam_role.external_secrets[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Action = [
            "secretsmanager:DescribeSecret",
            "secretsmanager:GetSecretValue"
          ]
          Resource = var.external_secret_arns
        }
      ],
      var.kms_key_arn == "" ? [] : [
        {
          Effect   = "Allow"
          Action   = ["kms:Decrypt"]
          Resource = [var.kms_key_arn]
        }
      ]
    )
  })
}

resource "helm_release" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_chart_version
  namespace        = "external-secrets"
  create_namespace = true
  wait             = true
  timeout          = 900

  values = local.external_secrets_integration_enabled ? [
    yamlencode({
      serviceAccount = {
        create = true
        name   = "external-secrets"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets[0].arn
        }
      }
    })
  ] : []

  depends_on = [aws_iam_role_policy.external_secrets]
}

resource "helm_release" "external_secret_resources" {
  count = local.external_secrets_integration_enabled ? 1 : 0

  name      = "astronomy-shop-external-secrets"
  chart     = "${path.module}/chart"
  namespace = var.namespace
  wait      = true
  timeout   = 600

  values = [
    yamlencode({
      awsRegion          = var.aws_region
      namespace          = var.namespace
      targetSecretName   = var.external_secret_target_name
      databaseSecretName = var.database_secret_target_name
      runtimeSecretKey   = try(var.external_secret_arns[0], "")
      databaseSecretKey  = try(var.external_secret_arns[1], "")
    })
  ]

  depends_on = [helm_release.external_secrets]
}
