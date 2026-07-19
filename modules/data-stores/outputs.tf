output "rds_endpoint" { value = try(aws_db_instance.postgres[0].address, null) }
output "rds_instance_arn" { value = try(aws_db_instance.postgres[0].arn, null) }
output "rds_master_user_secret_arn" { value = try(aws_db_instance.postgres[0].master_user_secret[0].secret_arn, null) }
output "redis_primary_endpoint" { value = try(aws_elasticache_replication_group.redis[0].primary_endpoint_address, null) }
output "redis_replication_group_arn" { value = try(aws_elasticache_replication_group.redis[0].arn, null) }
