variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "github_org" {
  type    = string
  default = "Prasanna-1010-AWS"
}

variable "github_app_repository" {
  type    = string
  default = "astronomy-shop-app"
}

variable "create_github_oidc_provider" {
  description = "Create the account-level GitHub Actions OIDC provider in this shared state."
  type        = bool
  default     = true
}

variable "github_oidc_provider_arn" {
  description = "Use an existing GitHub OIDC provider ARN and set create_github_oidc_provider to false when one already exists."
  type        = string
  default     = null
  nullable    = true
}
