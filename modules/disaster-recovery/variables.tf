variable "name" { type = string }
variable "environment" { type = string }
variable "kms_key_arn" {
  type        = string
  default     = ""
  description = "Deprecated compatibility input. The DR module creates a key in its own provider region."
}

variable "enable_replica_bucket" {
  type    = bool
  default = false
}

variable "replica_noncurrent_version_retention_days" {
  type    = number
  default = 90
}

variable "tags" {
  type    = map(string)
  default = {}
}
