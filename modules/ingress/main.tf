data "aws_iam_openid_connect_provider" "this" {
  arn = var.oidc_provider_arn
}

data "aws_caller_identity" "current" {}

locals {
  oidc_provider = replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")

  service_accounts = {
    aws_load_balancer_controller = {
      namespace = "kube-system"
      name      = "aws-load-balancer-controller"
    }
    external_dns = {
      namespace = "external-dns"
      name      = "external-dns"
    }
    cert_manager = {
      namespace = "cert-manager"
      name      = "cert-manager"
    }
  }
}

resource "aws_s3_bucket" "alb_access_logs" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = "${var.name}-${var.environment}-${data.aws_caller_identity.current.account_id}-alb-logs"
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "alb_access_logs" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket                  = aws_s3_bucket.alb_access_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "alb_access_logs" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_access_logs" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_access_logs" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id

  rule {
    id     = "alb-access-log-retention"
    status = "Enabled"

    filter { prefix = "" }

    expiration {
      days = var.alb_access_logs_retention_days
    }
  }
}

data "aws_iam_policy_document" "alb_access_logs" {
  count = var.enable_alb_access_logs ? 1 : 0

  statement {
    sid = "AllowElasticLoadBalancingLogDelivery"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.alb_access_logs[0].arn}/${var.alb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.alb_access_logs[0].id
  policy = data.aws_iam_policy_document.alb_access_logs[0].json
}

data "aws_iam_policy_document" "irsa_assume_role" {
  for_each = local.service_accounts

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
      values   = ["system:serviceaccount:${each.value.namespace}:${each.value.name}"]
    }
  }
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  name               = "${var.name}-${var.environment}-aws-lbc"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role["aws_load_balancer_controller"].json
  tags               = var.tags
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name = "${var.name}-${var.environment}-aws-lbc"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeCoipPools",
          "ec2:DescribeInstances",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeIpamPools",
          "ec2:DescribeIpv6Pools",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribePrefixLists",
          "ec2:DescribeRouteTables",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcClassicLink",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeVpcs",
          "ec2:GetCoipPoolUsage",
          "ec2:GetSecurityGroupsForVpc",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DeleteSecurityGroup",
          "cognito-idp:DescribeUserPoolClient",
          "acm:DescribeCertificate",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
          "shield:DescribeProtection",
          "shield:CreateProtection",
          "shield:DeleteProtection",
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

resource "aws_iam_role" "external_dns" {
  name               = "${var.name}-${var.environment}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role["external_dns"].json
  tags               = var.tags
}

resource "aws_iam_policy" "external_dns" {
  name = "${var.name}-${var.environment}-external-dns"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = var.route53_zone_arns
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListHostedZonesByName",
          "route53:ListTagsForResource"
        ]
        Resource = "*"
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

resource "aws_iam_role" "cert_manager" {
  name               = "${var.name}-${var.environment}-cert-manager"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role["cert_manager"].json
  tags               = var.tags
}

resource "aws_iam_policy" "cert_manager" {
  name = "${var.name}-${var.environment}-cert-manager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = var.route53_zone_arns
      },
      {
        Effect = "Allow"
        Action = [
          "route53:GetChange",
          "route53:ListHostedZones",
          "route53:ListHostedZonesByName"
        ]
        Resource = "*"
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cert_manager" {
  role       = aws_iam_role.cert_manager.name
  policy_arn = aws_iam_policy.cert_manager.arn
}

resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = var.aws_load_balancer_controller_chart_version
  namespace        = "kube-system"
  create_namespace = false
  wait             = true
  timeout          = 900

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "region"
    value = data.aws_region.current.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = local.service_accounts.aws_load_balancer_controller.name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller.arn
  }

  depends_on = [aws_iam_role_policy_attachment.aws_load_balancer_controller]
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = var.external_dns_chart_version
  namespace        = "external-dns"
  create_namespace = true
  timeout          = 900

  set {
    name  = "provider.name"
    value = "aws"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = local.service_accounts.external_dns.name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_dns.arn
  }

  depends_on = [
    aws_iam_role_policy_attachment.external_dns,
    helm_release.aws_load_balancer_controller,
  ]
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_chart_version
  namespace        = "cert-manager"
  create_namespace = true
  wait             = true
  timeout          = 900

  set {
    name  = "crds.enabled"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = local.service_accounts.cert_manager.name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cert_manager.arn
  }

  depends_on = [
    aws_iam_role_policy_attachment.cert_manager,
    helm_release.aws_load_balancer_controller,
  ]
}

resource "helm_release" "cluster_issuer" {
  count = var.create_cluster_issuer && var.cluster_issuer_email != "" ? 1 : 0

  name      = "astronomy-shop-cluster-issuer"
  chart     = "${path.module}/chart"
  namespace = "cert-manager"
  wait      = true
  timeout   = 600

  values = [
    yamlencode({
      email     = var.cluster_issuer_email
      server    = var.cluster_issuer_server
      awsRegion = data.aws_region.current.name
    })
  ]

  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_ingress_v1" "application" {
  count = var.create_application_ingress && var.application_hostname != "" && var.alb_certificate_arn != "" ? 1 : 0

  metadata {
    name      = "${var.name}-${var.environment}-public"
    namespace = var.application_namespace

    annotations = merge(
      {
        "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"      = "ip"
        "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\":80},{\"HTTPS\":443}]"
        "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
        "alb.ingress.kubernetes.io/certificate-arn"  = var.alb_certificate_arn
        "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
        "alb.ingress.kubernetes.io/healthcheck-path" = var.alb_healthcheck_path
        "external-dns.alpha.kubernetes.io/hostname"  = var.application_hostname
      },
      var.alb_waf_acl_arn == "" ? {} : {
        "alb.ingress.kubernetes.io/wafv2-acl-arn" = var.alb_waf_acl_arn
      },
      var.application_origin_verification_header_name == "" || var.application_origin_verification_header_value == "" ? {} : {
        "alb.ingress.kubernetes.io/conditions.${var.application_service_name}" = jsonencode([
          {
            field = "http-header"
            httpHeaderConfig = {
              httpHeaderName = var.application_origin_verification_header_name
              values         = [var.application_origin_verification_header_value]
            }
          }
        ])
      }
    )
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = var.application_hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = var.application_service_name
              port {
                number = var.application_service_port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.aws_load_balancer_controller, helm_release.external_dns]
}

data "aws_region" "current" {}
