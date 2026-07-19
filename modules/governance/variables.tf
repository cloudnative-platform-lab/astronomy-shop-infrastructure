variable "name" { type = string }
variable "environment" { type = string }

variable "enable_cloudtrail" {
  type    = bool
  default = true
}

variable "enable_config" {
  type    = bool
  default = false
}

variable "audit_retention_days" {
  type    = number
  default = 365
}

variable "tags" {
  type    = map(string)
  default = {}
}
