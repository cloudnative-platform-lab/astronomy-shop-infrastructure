module "karpenter" {
  source                 = "../../modules/karpenter"
  enabled                = var.enable_karpenter
  name                   = local.project
  environment            = local.environment
  cluster_name           = data.terraform_remote_state.bootstrap.outputs.cluster_name
  cluster_endpoint       = data.terraform_remote_state.bootstrap.outputs.cluster_endpoint
  oidc_provider_arn      = data.terraform_remote_state.bootstrap.outputs.oidc_provider_arn
  node_security_group_id = data.terraform_remote_state.bootstrap.outputs.node_security_group_id
  private_subnet_ids     = data.terraform_remote_state.bootstrap.outputs.private_subnet_ids
  allowed_instance_types = ["t3.small", "c7i-flex.large", "m7i-flex.large"]
  tags                   = local.common_tags
}

module "ingress" {
  count                                        = var.enable_ingress ? 1 : 0
  source                                       = "../../modules/ingress"
  name                                         = local.project
  environment                                  = local.environment
  cluster_name                                 = data.terraform_remote_state.bootstrap.outputs.cluster_name
  vpc_id                                       = data.terraform_remote_state.bootstrap.outputs.vpc_id
  oidc_provider_arn                            = data.terraform_remote_state.bootstrap.outputs.oidc_provider_arn
  route53_zone_arns                            = var.route53_zone_arns
  create_application_ingress                   = var.create_application_ingress
  application_namespace                        = local.effective_app_namespace
  application_hostname                         = var.application_hostname
  application_service_name                     = "frontend-proxy"
  application_service_port                     = 8080
  alb_certificate_arn                          = var.alb_certificate_arn != "" ? var.alb_certificate_arn : try(data.terraform_remote_state.bootstrap.outputs.alb_certificate_arn, "")
  alb_waf_acl_arn                              = var.alb_waf_acl_arn
  application_origin_verification_header_name  = try(data.terraform_remote_state.bootstrap.outputs.edge_origin_verification_header_name, "")
  application_origin_verification_header_value = try(data.terraform_remote_state.bootstrap.outputs.edge_origin_verification_header_value, "")
  create_cluster_issuer                        = var.create_cert_manager_cluster_issuer
  cluster_issuer_email                         = var.cert_manager_email != "" ? var.cert_manager_email : var.alert_email
  tags                                         = local.common_tags
}

module "argo_rollouts" {
  source  = "../../modules/argo-rollouts"
  enabled = var.enable_argo_rollouts
}

module "kubernetes_security" {
  count          = var.enable_kubernetes_security ? 1 : 0
  source         = "../../modules/kubernetes-security"
  namespaces     = length(var.app_namespaces) > 0 ? var.app_namespaces : local.app_namespaces
  enable_kyverno = var.enable_kyverno
  enable_falco   = var.enable_falco
  falco_values = [yamlencode({
    driver = {
      kind = "modern_ebpf"
    }
    resources = {
      requests = {
        cpu    = "50m"
        memory = "256Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "512Mi"
      }
    }
    tolerations = [
      {
        operator = "Exists"
        effect   = "NoSchedule"
      },
      {
        operator = "Exists"
        effect   = "NoExecute"
      }
    ]
    podPriorityClassName = "falco-node-security"
  })]
  kyverno_chart_version            = var.kyverno_chart_version
  kyverno_values                   = var.kyverno_values
  enable_signed_image_policy       = var.enable_signed_image_policy
  signed_image_namespaces          = [local.effective_app_namespace]
  signed_image_repository_patterns = length(var.signed_image_repository_patterns) > 0 ? var.signed_image_repository_patterns : ["*.dkr.ecr.${var.aws_region}.amazonaws.com/${local.project}/*"]
  cosign_subject_regexp            = var.cosign_subject_regexp
}

module "istio" {
  source                                 = "../../modules/istio"
  enabled                                = var.enable_istio
  application_namespace                  = local.effective_app_namespace
  enable_application_namespace_injection = var.enable_istio_sidecar_injection

  depends_on = [module.kubernetes_security]
}

module "workload_foundation" {
  count                   = var.enable_workload_foundation ? 1 : 0
  source                  = "../../modules/workload-foundation"
  name                    = local.project
  environment             = local.environment
  namespace               = local.effective_app_namespace
  create_namespace        = false
  services                = local.services
  enable_external_secrets = var.enable_external_secrets
  aws_region              = var.aws_region
  oidc_provider_arn       = data.terraform_remote_state.bootstrap.outputs.oidc_provider_arn
  kms_key_arn             = data.terraform_remote_state.bootstrap.outputs.kms_key_arn
  external_secret_arns = compact([
    try(data.terraform_remote_state.bootstrap.outputs.app_config_secret_arn, ""),
    try(data.terraform_remote_state.bootstrap.outputs.rds_master_user_secret_arn, "")
  ])
  app_storage_bucket_arn = try(data.terraform_remote_state.bootstrap.outputs.app_storage_bucket_arn, "")
  tags                   = local.common_tags
  depends_on             = [module.kubernetes_security, module.istio]
}

module "gitops" {
  count                      = var.enable_gitops ? 1 : 0
  source                     = "../../modules/gitops"
  name                       = local.project
  environment                = local.environment
  repository_url             = var.gitops_repository_url
  repository_ssh_private_key = var.gitops_repository_ssh_private_key_path != "" && fileexists(pathexpand(var.gitops_repository_ssh_private_key_path)) ? file(pathexpand(var.gitops_repository_ssh_private_key_path)) : null
  root_application_path      = "argocd/appsets/${local.environment}"
  target_revision            = "main"
  install_argocd             = var.enable_gitops
  create_root_application    = var.create_gitops_root_application
  tags                       = local.common_tags
  depends_on                 = [module.karpenter, module.argo_rollouts, module.istio, module.observability, module.workload_foundation]
}

module "observability" {
  source                         = "../../modules/observability"
  name                           = local.project
  environment                    = local.environment
  alert_email                    = var.alert_email
  cluster_name                   = data.terraform_remote_state.bootstrap.outputs.cluster_name
  aws_region                     = var.aws_region
  enable_alertmanager_sns        = var.enable_alertmanager_sns
  enable_monitoring_stack        = var.enable_observability
  enable_metrics_server          = var.enable_metrics_server
  enable_alertmanager            = var.enable_alertmanager
  enable_loki                    = var.enable_loki
  enable_opentelemetry_collector = var.enable_opentelemetry_collector
  enable_tempo                   = var.enable_tempo
  enable_persistence             = var.enable_observability_persistence
  tags                           = local.common_tags

  depends_on = [module.ingress]
}

module "cloudwatch" {
  count                      = var.enable_cloudwatch ? 1 : 0
  source                     = "../../modules/cloudwatch"
  name                       = local.project
  environment                = local.environment
  cluster_name               = data.terraform_remote_state.bootstrap.outputs.cluster_name
  alert_topic_arn            = module.observability.alerts_topic_arn
  application_log_group_name = try(data.terraform_remote_state.bootstrap.outputs.container_insights_application_log_group_name, "")
  log_retention_days         = var.cloudwatch_log_retention_days
  tags                       = local.common_tags
}

module "velero" {
  count             = var.enable_velero ? 1 : 0
  source            = "../../modules/velero"
  name              = local.project
  environment       = local.environment
  oidc_provider_arn = data.terraform_remote_state.bootstrap.outputs.oidc_provider_arn
  kms_key_arn       = data.terraform_remote_state.bootstrap.outputs.kms_key_arn
  tags              = local.common_tags
}

module "finops" {
  count                  = var.enable_finops ? 1 : 0
  source                 = "../../modules/finops"
  name                   = local.project
  environment            = local.environment
  monthly_budget_usd     = 350
  alert_email            = var.alert_email
  enable_kubecost        = var.enable_kubecost
  enable_persistence     = var.enable_observability_persistence
  kubecost_chart_version = var.kubecost_chart_version
  kubecost_values        = var.kubecost_values
  tags                   = local.common_tags
  depends_on             = [module.observability]
}

