variable "name" { type = string }
variable "environment" { type = string }
variable "oidc_provider_arn" { type = string }
variable "namespace" { type = string }
variable "service_account_name" { type = string }
variable "role_name" { type = string }

variable "policy_json" {
  type    = string
  default = null
}

variable "managed_policy_arns" {
  type    = list(string)
  default = []
}

variable "create_service_account" {
  type    = bool
  default = true
}

variable "automount_service_account_token" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
