module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                         = "${var.name}-${var.environment}"
  cluster_version                      = var.cluster_version
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_endpoint_private_access      = true

  enable_cluster_creator_admin_permissions = true

  access_entries = {
    for admin_role_arn in var.admin_role_arns : replace(replace(replace(admin_role_arn, ":", "_"), "/", "_"), "-", "_") => {
      principal_arn = admin_role_arn
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  cluster_enabled_log_types = var.cluster_enabled_log_types

  eks_managed_node_groups = {
    baseline = {
      name                     = "${var.environment}-base"
      iam_role_name            = "${var.name}-${var.environment}-node"
      iam_role_use_name_prefix = false
      instance_types           = var.node_instance_types
      disk_size                = var.node_disk_size
      min_size                 = var.node_min_size
      desired_size             = var.node_desired_size
      max_size                 = var.node_max_size

      labels = {
        workload = "baseline"
      }
    }
  }

  cluster_addons = {
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }
    vpc-cni                = { most_recent = true }
    eks-pod-identity-agent = { most_recent = true }
  }

  tags = merge(var.tags, {
    "karpenter.sh/discovery" = "${var.name}-${var.environment}"
  })
}

data "aws_iam_policy_document" "pod_identity_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  name               = "${var.name}-${var.environment}-ebs-csi"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  role       = aws_iam_role.ebs_csi[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_pod_identity_association" "ebs_csi" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi[0].arn

  depends_on = [aws_iam_role_policy_attachment.ebs_csi]
}

resource "aws_eks_addon" "ebs_csi" {
  count = var.enable_ebs_csi_driver ? 1 : 0

  cluster_name                = module.eks.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  tags                        = var.tags

  depends_on = [aws_eks_pod_identity_association.ebs_csi]
}

resource "aws_iam_role" "cloudwatch_observability" {
  count = var.enable_cloudwatch_observability ? 1 : 0

  name               = "${var.name}-${var.environment}-cloudwatch-observability"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
  tags               = var.tags
}

resource "aws_cloudwatch_log_group" "container_insights_application" {
  count = var.enable_cloudwatch_observability ? 1 : 0

  name              = "/aws/containerinsights/${module.eks.cluster_name}/application"
  retention_in_days = var.environment == "prod" ? 90 : (var.environment == "staging" ? 30 : 7)
  tags              = var.tags
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count = var.enable_cloudwatch_observability ? 1 : 0

  role       = aws_iam_role.cloudwatch_observability[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "xray_write" {
  count = var.enable_cloudwatch_observability ? 1 : 0

  role       = aws_iam_role.cloudwatch_observability[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_eks_pod_identity_association" "cloudwatch_agent" {
  count = var.enable_cloudwatch_observability ? 1 : 0

  cluster_name    = module.eks.cluster_name
  namespace       = "amazon-cloudwatch"
  service_account = "cloudwatch-agent"
  role_arn        = aws_iam_role.cloudwatch_observability[0].arn

  depends_on = [
    aws_iam_role_policy_attachment.cloudwatch_agent,
    aws_iam_role_policy_attachment.xray_write
  ]
}

resource "aws_eks_addon" "cloudwatch_observability" {
  count = var.enable_cloudwatch_observability ? 1 : 0

  cluster_name                = module.eks.cluster_name
  addon_name                  = "amazon-cloudwatch-observability"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  tags                        = var.tags

  depends_on = [
    aws_eks_pod_identity_association.cloudwatch_agent,
    aws_cloudwatch_log_group.container_insights_application
  ]
}
