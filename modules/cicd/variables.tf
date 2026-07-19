variable "name" { type = string }
variable "environment" { type = string }
variable "github_org" { type = string }
variable "github_repo" { type = string }

variable "github_oidc_provider_arn" {
  description = "Existing GitHub Actions OIDC provider ARN. Leave null to create one in this state."
  type        = string
  default     = null
}

variable "ecr_repository_arns" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "create_github_oidc_provider" {
  type    = bool
  default = false
}