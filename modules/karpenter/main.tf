module "karpenter" {
  count = var.enabled ? 1 : 0

  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  cluster_name           = var.cluster_name
  irsa_oidc_provider_arn = var.oidc_provider_arn
  enable_irsa            = true

  tags = var.tags
}

resource "helm_release" "controller" {
  count = var.enabled ? 1 : 0

  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = var.controller_chart_version
  namespace        = "karpenter"
  create_namespace = true
  wait             = true
  timeout          = 900

  values = [
    yamlencode({
      settings = {
        clusterName       = var.cluster_name
        clusterEndpoint   = var.cluster_endpoint
        interruptionQueue = try(module.karpenter[0].queue_name, "")
      }
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = module.karpenter[0].iam_role_arn
        }
      }
      controller = {
        resources = {
          requests = {
            cpu    = "250m"
            memory = "512Mi"
          }
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
        }
      }
    })
  ]

  depends_on = [
    aws_ec2_tag.subnet_discovery,
    aws_ec2_tag.security_group_discovery,
    aws_iam_role_policy.instance_type_guardrail
  ]
}

resource "helm_release" "provisioning" {
  count = var.enabled ? 1 : 0

  name      = "karpenter-provisioning"
  chart     = "${path.module}/chart"
  namespace = "karpenter"
  wait      = true
  timeout   = 600

  values = [
    yamlencode({
      clusterName          = var.cluster_name
      nodeRoleName         = module.karpenter[0].node_iam_role_name
      allowedInstanceTypes = var.allowed_instance_types
      capacityTypes        = var.capacity_types
      architecture         = var.architecture
      cpuLimit             = var.nodepool_cpu_limit
    })
  ]

  depends_on = [helm_release.controller]
}

resource "aws_ec2_tag" "subnet_discovery" {
  for_each    = var.enabled ? toset(var.private_subnet_ids) : toset([])
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

resource "aws_ec2_tag" "security_group_discovery" {
  count       = var.enabled ? 1 : 0
  resource_id = var.node_security_group_id
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

resource "aws_iam_role_policy" "instance_type_guardrail" {
  count = var.enabled ? 1 : 0

  name = "${var.name}-${var.environment}-karpenter-instance-type-guardrail"
  role = module.karpenter[0].iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyUnapprovedInstanceTypes"
        Effect   = "Deny"
        Action   = "ec2:RunInstances"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "ec2:InstanceType" = var.allowed_instance_types
          }
        }
      }
    ]
  })
}
