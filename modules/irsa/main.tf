data "aws_iam_openid_connect_provider" "this" {
  arn = var.oidc_provider_arn
}

locals {
  oidc_provider        = replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")
  namespace            = var.namespace
  service_account_name = var.service_account_name
}

resource "aws_iam_role" "this" {
  name = "${var.name}-${var.environment}-${var.role_name}"

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
            "${local.oidc_provider}:sub" = "system:serviceaccount:${local.namespace}:${local.service_account_name}"
            "${local.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "this" {
  count       = var.policy_json == null ? 0 : 1
  name        = "${var.name}-${var.environment}-${var.role_name}"
  description = "IRSA policy for ${local.namespace}/${local.service_account_name}"
  policy      = var.policy_json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each   = toset(var.managed_policy_arns)
  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "inline" {
  count      = var.policy_json == null ? 0 : 1
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[0].arn
}

resource "kubernetes_service_account_v1" "this" {
  count = var.create_service_account ? 1 : 0

  metadata {
    name      = local.service_account_name
    namespace = local.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
    }
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  automount_service_account_token = var.automount_service_account_token
}
