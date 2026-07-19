variable "name" { type = string }
variable "environment" { type = string }
variable "oidc_provider_arn" { type = string }

variable "bucket_name" {
  type    = string
  default = null
}

variable "namespace" {
  type    = string
  default = "velero"
}

variable "service_account_name" {
  type    = string
  default = "velero"
}

variable "chart_version" {
  type    = string
  default = null
}

variable "aws_plugin_image" {
  type    = string
  default = "velero/velero-plugin-for-aws:v1.10.0"
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "force_destroy_bucket" {
  type    = bool
  default = false
}

variable "backup_retention_days" {
  type    = number
  default = 30
}

variable "create_default_schedule" {
  type    = bool
  default = true
}

variable "backup_schedule" {
  type    = string
  default = "0 2 * * *"
}

variable "backup_ttl" {
  type    = string
  default = "720h"
}

variable "included_namespaces" {
  type    = list(string)
  default = ["*"]
}

variable "excluded_namespaces" {
  type    = list(string)
  default = ["kube-system", "velero"]
}

variable "snapshot_volumes" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
