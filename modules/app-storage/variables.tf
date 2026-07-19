variable "name" { type = string }
variable "environment" { type = string }
variable "kms_key_arn" { type = string }

variable "enable_replication" {
  type    = bool
  default = false
}

variable "replication_destination_bucket_arn" {
  type    = string
  default = null
}
variable "replication_destination_kms_key_arn" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
