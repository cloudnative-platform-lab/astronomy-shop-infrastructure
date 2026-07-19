variable "name" { type = string }
variable "environment" { type = string }

variable "namespace" {
  type    = string
  default = "astronomy-shop"
}

variable "create_namespace" {
  type    = bool
  default = true
}

variable "services" {
  type    = list(string)
  default = []
}

variable "enable_external_secrets" {
  type    = bool
  default = true
}
variable "aws_region" {
  type    = string
  default = "ap-south-1"
}
variable "oidc_provider_arn" {
  type    = string
  default = ""
}
variable "kms_key_arn" {
  type    = string
  default = ""
}
variable "external_secret_arns" {
  type    = list(string)
  default = []
}
variable "external_secret_target_name" {
  type    = string
  default = "astronomy-shop-runtime"
}
variable "database_secret_target_name" {
  type    = string
  default = "astronomy-shop-database"
}
variable "app_storage_bucket_arn" {
  description = "Application S3 bucket granted only to the designated workload service account."
  type        = string
  default     = ""
}
variable "app_storage_service_account_name" {
  type    = string
  default = "image-provider"
}
variable "external_secrets_chart_version" {
  type    = string
  default = "0.9.20"
}

variable "tags" {
  type    = map(string)
  default = {}
}
