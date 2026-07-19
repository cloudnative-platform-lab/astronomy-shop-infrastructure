variable "name" { type = string }
variable "environment" { type = string }
variable "kms_key_arn" { type = string }
variable "backup_resource_arns" {
  type    = list(string)
  default = []
}
variable "copy_destination_vault_arn" {
  type    = string
  default = null
}
variable "daily_retention_days" {
  type    = number
  default = 35
}
variable "weekly_retention_days" {
  type    = number
  default = 90
}

variable "tags" {
  type    = map(string)
  default = {}
}
