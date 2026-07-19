resource "aws_security_group" "rds" {
  count = var.enable_rds ? 1 : 0

  name        = "${var.name}-${var.environment}-rds"
  description = "Allow PostgreSQL from EKS workloads"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "rds_from_apps" {
  for_each                 = var.enable_rds ? { for index, security_group_id in var.app_security_group_ids : tostring(index) => security_group_id } : {}
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds[0].id
  source_security_group_id = each.value
}

resource "aws_db_instance" "postgres" {
  count = var.enable_rds ? 1 : 0

  identifier                      = "${var.name}-${var.environment}-postgres"
  engine                          = "postgres"
  engine_version                  = "16"
  instance_class                  = var.rds_instance_class
  allocated_storage               = var.rds_allocated_storage
  max_allocated_storage           = var.rds_max_allocated_storage
  storage_type                    = "gp3"
  db_name                         = "astronomyshop"
  username                        = "app_admin"
  manage_master_user_password     = true
  multi_az                        = var.rds_multi_az
  storage_encrypted               = true
  kms_key_id                      = var.kms_key_arn
  db_subnet_group_name            = var.database_subnet_group_name
  vpc_security_group_ids          = [aws_security_group.rds[0].id]
  backup_retention_period         = var.rds_backup_retention_period
  deletion_protection             = var.rds_deletion_protection
  skip_final_snapshot             = var.environment != "prod"
  final_snapshot_identifier       = var.environment == "prod" ? "${var.name}-${var.environment}-postgres-final" : null
  performance_insights_enabled    = var.rds_performance_insights_enabled
  performance_insights_kms_key_id = var.rds_performance_insights_enabled ? var.kms_key_arn : null
  copy_tags_to_snapshot           = true
  delete_automated_backups        = var.environment != "prod"
  auto_minor_version_upgrade      = true
  apply_immediately               = var.environment != "prod"
  tags                            = var.tags
}

resource "aws_security_group" "redis" {
  count = var.enable_redis ? 1 : 0

  name        = "${var.name}-${var.environment}-redis"
  description = "Allow Redis from EKS workloads"
  vpc_id      = var.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "redis_from_apps" {
  for_each                 = var.enable_redis ? { for index, security_group_id in var.app_security_group_ids : tostring(index) => security_group_id } : {}
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.redis[0].id
  source_security_group_id = each.value
}

resource "aws_elasticache_subnet_group" "redis" {
  count = var.enable_redis ? 1 : 0

  name       = "${var.name}-${var.environment}-redis"
  subnet_ids = var.database_subnet_ids
  tags       = var.tags
}

resource "aws_elasticache_replication_group" "redis" {
  count = var.enable_redis ? 1 : 0

  replication_group_id       = "${var.name}-${var.environment}-redis"
  description                = "Astronomy Shop Redis cache and cart acceleration"
  engine                     = "redis"
  node_type                  = var.redis_node_type
  num_cache_clusters         = var.redis_num_cache_nodes
  automatic_failover_enabled = var.redis_num_cache_nodes > 1
  multi_az_enabled           = var.redis_num_cache_nodes > 1
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  transit_encryption_mode    = "required"
  snapshot_retention_limit   = var.redis_snapshot_retention_limit
  snapshot_window            = "03:00-04:00"
  maintenance_window         = "sun:04:00-sun:05:00"
  auto_minor_version_upgrade = true
  subnet_group_name          = aws_elasticache_subnet_group.redis[0].name
  security_group_ids         = [aws_security_group.redis[0].id]
  kms_key_id                 = var.kms_key_arn
  tags                       = var.tags
}
