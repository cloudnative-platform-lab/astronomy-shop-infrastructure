variable "name" { type = string }
variable "environment" { type = string }

variable "domain_name" {
  type    = string
  default = ""
}

variable "subject_alternative_names" {
  type    = list(string)
  default = []
}

variable "route53_zone_id" {
  type    = string
  default = null
}

variable "create_validation_records" {
  type    = bool
  default = false
}
variable "validation_record_fqdns" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
