variable "name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "database_subnet_group_name" { type = string }
variable "database_subnet_ids" { type = list(string) }
variable "app_security_group_ids" { type = list(string) }

variable "enable_rds" {
  type    = bool
  default = false
}

variable "rds_instance_class" {
  type = string

  validation {
    condition     = contains(["db.t3.micro", "db.t4g.micro"], var.rds_instance_class)
    error_message = "RDS instance class must be db.t3.micro or db.t4g.micro for the restricted AWS account profile."
  }
}
variable "rds_allocated_storage" { type = number }
variable "rds_max_allocated_storage" {
  type    = number
  default = 100
}
variable "rds_multi_az" {
  type    = bool
  default = false
}
variable "rds_backup_retention_period" {
  type    = number
  default = 1
}
variable "rds_performance_insights_enabled" {
  type    = bool
  default = false
}
variable "rds_deletion_protection" {
  type    = bool
  default = false
}

variable "enable_redis" {
  type    = bool
  default = false
}

variable "redis_node_type" {
  type = string

  validation {
    condition     = contains(["cache.t3.micro", "cache.t4g.micro"], var.redis_node_type)
    error_message = "Redis node type must be cache.t3.micro or cache.t4g.micro when Redis is enabled."
  }
}
variable "redis_num_cache_nodes" { type = number }
variable "redis_snapshot_retention_limit" {
  type    = number
  default = 1
}
variable "kms_key_arn" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
