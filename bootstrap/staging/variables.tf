variable "aws_region" {
  type    = string
  default = "ap-south-1"
}
variable "dr_region" {
  type    = string
  default = "ap-southeast-1"
}
variable "azs" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}
variable "domain_name" {
  type    = string
  default = ""
}
variable "cloudfront_certificate_arn" {
  type    = string
  default = ""
}
variable "certificate_subject_alternative_names" {
  type    = list(string)
  default = []
}
variable "create_certificate_validation_records" {
  type    = bool
  default = false
}
variable "alb_dns_name" {
  type    = string
  default = ""
}
variable "enable_edge" {
  type    = bool
  default = false
}
variable "github_org" {
  type    = string
  default = "Prasanna-1010-AWS"
}
variable "github_repo" {
  type    = string
  default = "astronomy-shop-infrastructure"
}
variable "github_oidc_provider_arn" {
  type    = string
  default = null
}
variable "alert_email" {
  type    = string
  default = ""
}
variable "enable_nat_gateway" {
  type    = bool
  default = true
}
variable "single_nat_gateway" {
  type    = bool
  default = false
}
variable "flow_logs_bucket_arn" {
  type    = string
  default = ""
}
variable "eks_endpoint_public_access" {
  type    = bool
  default = true
}
variable "eks_endpoint_public_access_cidrs" {
  type        = list(string)
  description = "Trusted public CIDRs allowed to reach the EKS API. Never use 0.0.0.0/0 outside development."

  validation {
    condition     = !contains(var.eks_endpoint_public_access_cidrs, "0.0.0.0/0")
    error_message = "Staging EKS API access must be restricted to trusted CIDRs."
  }
}
variable "enable_flow_logs" {
  type    = bool
  default = true
}
variable "flow_logs_retention_days" {
  type    = number
  default = 30
}
variable "interface_endpoint_services" {
  type    = list(string)
  default = []
}
variable "eks_admin_role_arns" {
  type    = list(string)
  default = []
}
variable "enable_ebs_csi_driver" {
  type    = bool
  default = true
}
variable "enable_cloudwatch_observability" {
  type    = bool
  default = true
}
variable "enable_route53" {
  type    = bool
  default = false
}
variable "route53_zone_name" {
  type    = string
  default = ""
}
variable "route53_zone_id" {
  type    = string
  default = null
}
variable "route53_record_name" {
  type    = string
  default = ""
}
variable "create_route53_zone" {
  type    = bool
  default = false
}
variable "enable_guardduty" {
  type    = bool
  default = true
}
variable "enable_security_hub" {
  type    = bool
  default = true
}

variable "enable_inspector" {
  type    = bool
  default = true
}
variable "enable_rds" {
  type    = bool
  default = true
}
variable "enable_redis" {
  type    = bool
  default = true
}
variable "rds_multi_az" {
  type    = bool
  default = false
}
variable "rds_backup_retention_period" {
  type    = number
  default = 7
}
variable "rds_max_allocated_storage" {
  type    = number
  default = 100
}
variable "rds_performance_insights_enabled" {
  type    = bool
  default = true
}
variable "rds_deletion_protection" {
  type    = bool
  default = false
}
variable "redis_num_cache_nodes" {
  type    = number
  default = 1
}
variable "redis_snapshot_retention_limit" {
  type    = number
  default = 3
}
variable "enable_identity_center" {
  type    = bool
  default = false
}
variable "identity_store_id" {
  type    = string
  default = null
}
variable "sso_instance_arn" {
  type    = string
  default = null
}
variable "identity_center_account_id" {
  type    = string
  default = null
}
variable "identity_permission_sets" {
  type = map(object({
    description      = optional(string, null)
    session_duration = optional(string, "PT8H")
    managed_policies = optional(list(string), [])
  }))
  default = {}
}
variable "identity_group_assignments" {
  type = map(object({
    group_id            = string
    permission_set_name = string
  }))
  default = {}
}
variable "enable_cloudtrail" {
  type    = bool
  default = true
}
variable "enable_config" {
  type    = bool
  default = false
}
variable "enable_dr_replica_bucket" {
  type    = bool
  default = false
}
variable "backup_daily_retention_days" {
  type    = number
  default = 35
}
variable "backup_weekly_retention_days" {
  type    = number
  default = 90
}
variable "enable_backup" {
  type    = bool
  default = true
}
