module "networking" {
  source                      = "../../modules/networking"
  name                        = local.project
  environment                 = local.environment
  vpc_cidr                    = "10.10.0.0/16"
  azs                         = var.azs
  public_subnet_cidrs         = ["10.10.0.0/24", "10.10.1.0/24"]
  private_subnet_cidrs        = ["10.10.10.0/24", "10.10.11.0/24"]
  database_subnet_cidrs       = ["10.10.20.0/24", "10.10.21.0/24"]
  enable_nat_gateway          = var.enable_nat_gateway
  single_nat_gateway          = var.single_nat_gateway
  flow_logs_bucket_arn        = var.flow_logs_bucket_arn
  enable_flow_logs            = var.enable_flow_logs
  flow_logs_retention_days    = var.flow_logs_retention_days
  interface_endpoint_services = var.interface_endpoint_services
  tags                        = local.common_tags
}

module "security" {
  source              = "../../modules/security"
  name                = local.project
  environment         = local.environment
  enable_guardduty    = var.enable_guardduty
  enable_security_hub = var.enable_security_hub
  tags                = local.common_tags
}

module "identity" {
  source                 = "../../modules/identity"
  name                   = local.project
  environment            = local.environment
  enable_identity_center = var.enable_identity_center
  identity_store_id      = var.identity_store_id
  sso_instance_arn       = var.sso_instance_arn
  account_id             = var.identity_center_account_id
  permission_sets        = var.identity_permission_sets
  group_assignments      = var.identity_group_assignments
  tags                   = local.common_tags
}

module "eks" {
  source                               = "../../modules/eks"
  name                                 = local.project
  environment                          = local.environment
  cluster_version                      = "1.36"
  vpc_id                               = module.networking.vpc_id
  private_subnet_ids                   = var.enable_nat_gateway ? module.networking.private_subnet_ids : module.networking.public_subnet_ids
  cluster_endpoint_public_access       = var.eks_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.eks_endpoint_public_access_cidrs
  node_instance_types                  = var.eks_node_instance_types
  node_min_size                        = var.eks_node_min_size
  node_desired_size                    = var.eks_node_desired_size
  node_max_size                        = var.eks_node_max_size
  cluster_enabled_log_types            = []
  enable_ebs_csi_driver                = var.enable_ebs_csi_driver
  enable_cloudwatch_observability      = var.enable_cloudwatch_observability
  admin_role_arns                      = var.eks_admin_role_arns
  tags                                 = local.common_tags
}

module "data_stores" {
  source                           = "../../modules/data-stores"
  name                             = local.project
  environment                      = local.environment
  vpc_id                           = module.networking.vpc_id
  database_subnet_group_name       = module.networking.database_subnet_group_name
  database_subnet_ids              = module.networking.database_subnet_ids
  app_security_group_ids           = [module.eks.node_security_group_id]
  enable_rds                       = var.enable_rds
  rds_instance_class               = "db.t3.micro"
  rds_allocated_storage            = 20
  rds_max_allocated_storage        = var.rds_max_allocated_storage
  rds_multi_az                     = var.rds_multi_az
  rds_backup_retention_period      = var.rds_backup_retention_period
  rds_performance_insights_enabled = var.rds_performance_insights_enabled
  rds_deletion_protection          = var.rds_deletion_protection
  enable_redis                     = var.enable_redis
  redis_node_type                  = "cache.t3.micro"
  redis_num_cache_nodes            = var.redis_num_cache_nodes
  redis_snapshot_retention_limit   = var.redis_snapshot_retention_limit
  kms_key_arn                      = module.security.kms_key_arn
  tags                             = local.common_tags
}

module "disaster_recovery" {
  source                = "../../modules/disaster-recovery"
  providers             = { aws = aws.dr }
  name                  = local.project
  environment           = local.environment
  kms_key_arn           = module.security.kms_key_arn
  enable_replica_bucket = var.enable_dr_replica_bucket
  tags                  = local.common_tags
}

module "app_storage" {
  source                              = "../../modules/app-storage"
  name                                = local.project
  environment                         = local.environment
  kms_key_arn                         = module.security.kms_key_arn
  enable_replication                  = var.enable_dr_replica_bucket
  replication_destination_bucket_arn  = module.disaster_recovery.replica_bucket_arn
  replication_destination_kms_key_arn = module.disaster_recovery.replica_kms_key_arn
  tags                                = local.common_tags
}

module "certificates" {
  source                    = "../../modules/certificates"
  providers                 = { aws = aws.us_east_1 }
  name                      = local.project
  environment               = local.environment
  domain_name               = var.manage_edge_certificates ? var.domain_name : ""
  subject_alternative_names = var.manage_edge_certificates ? var.certificate_subject_alternative_names : []
  route53_zone_id           = var.route53_zone_id
  create_validation_records = false
  validation_record_fqdns   = module.alb_certificates.validation_record_fqdns
  tags                      = local.common_tags
}

module "alb_certificates" {
  source                    = "../../modules/certificates"
  name                      = local.project
  environment               = local.environment
  domain_name               = var.manage_edge_certificates ? var.domain_name : ""
  subject_alternative_names = var.manage_edge_certificates ? var.certificate_subject_alternative_names : []
  route53_zone_id           = var.route53_zone_id
  create_validation_records = var.create_certificate_validation_records
  tags                      = local.common_tags
}

module "application_config" {
  source     = "../../modules/application-config"
  secret_arn = module.security.app_config_secret_arn
  config = merge(
    {
      APP_STORAGE_BUCKET = module.app_storage.bucket_name
      ENVIRONMENT        = local.environment
    },
    var.enable_redis ? {
      VALKEY_ADDR = "${module.data_stores.redis_primary_endpoint}:6379"
      VALKEY_SSL  = "true"
    } : {},
    var.enable_rds ? {
      RDS_HOST              = module.data_stores.rds_endpoint
      RDS_PORT              = "5432"
      RDS_DATABASE          = "astronomyshop"
      RDS_MASTER_SECRET_ARN = module.data_stores.rds_master_user_secret_arn
    } : {}
  )
}

module "edge" {
  count                = var.enable_edge ? 1 : 0
  source               = "../../modules/edge"
  providers            = { aws = aws.us_east_1 }
  name                 = local.project
  environment          = local.environment
  domain_name          = var.domain_name
  alb_dns_name         = var.alb_dns_name
  alb_hosted_zone_id   = var.alb_hosted_zone_id
  origin_domain_name   = var.edge_origin_domain_name
  route53_zone_id      = var.route53_zone_id
  manage_origin_dns    = var.edge_manage_origin_dns
  certificate_arn      = var.cloudfront_certificate_arn != "" ? var.cloudfront_certificate_arn : (module.certificates.certificate_arn != null ? module.certificates.certificate_arn : "")
  rate_limit_per_5_min = 10000
  tags                 = local.common_tags
}

module "route53" {
  count                     = var.enable_route53 && var.enable_edge && var.enable_edge_public_dns_cutover ? 1 : 0
  source                    = "../../modules/route53"
  name                      = local.project
  environment               = local.environment
  create_zone               = var.create_route53_zone
  zone_id                   = var.route53_zone_id
  zone_name                 = var.route53_zone_name != "" ? var.route53_zone_name : var.domain_name
  record_name               = var.route53_record_name
  primary_alias_domain_name = module.edge[0].cloudfront_domain_name
  primary_alias_zone_id     = module.edge[0].cloudfront_hosted_zone_id
  tags                      = local.common_tags
}

module "governance" {
  source            = "../../modules/governance"
  name              = local.project
  environment       = local.environment
  enable_cloudtrail = var.enable_cloudtrail
  enable_config     = var.enable_config
  tags              = local.common_tags
}

module "backup" {
  count                      = var.enable_backup ? 1 : 0
  source                     = "../../modules/backup"
  name                       = local.project
  environment                = local.environment
  kms_key_arn                = module.security.kms_key_arn
  backup_resource_arns       = var.enable_rds ? [module.data_stores.rds_instance_arn] : []
  copy_destination_vault_arn = var.enable_dr_replica_bucket ? module.disaster_recovery.backup_vault_arn : null
  daily_retention_days       = var.backup_daily_retention_days
  weekly_retention_days      = var.backup_weekly_retention_days
  tags                       = local.common_tags
}
