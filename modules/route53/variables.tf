variable "name" { type = string }
variable "environment" { type = string }

variable "create_zone" {
  type    = bool
  default = false
}

variable "zone_id" {
  type    = string
  default = null
}

variable "zone_name" {
  type = string
}

variable "record_name" {
  type    = string
  default = ""
}

variable "record_types" {
  type    = list(string)
  default = ["A", "AAAA"]
}

variable "primary_alias_domain_name" {
  type = string
}

variable "primary_alias_zone_id" {
  type    = string
  default = "Z2FDTNDATAQYW2"
}

variable "secondary_alias_domain_name" {
  type    = string
  default = null
}

variable "secondary_alias_zone_id" {
  type    = string
  default = "Z2FDTNDATAQYW2"
}

variable "evaluate_target_health" {
  type    = bool
  default = false
}

variable "enable_failover" {
  type    = bool
  default = false
}

variable "primary_health_check_id" {
  type    = string
  default = null
}

variable "secondary_health_check_id" {
  type    = string
  default = null
}

variable "create_health_checks" {
  type    = bool
  default = false
}

variable "primary_health_check_fqdn" {
  type    = string
  default = null
}

variable "secondary_health_check_fqdn" {
  type    = string
  default = null
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "health_check_port" {
  type    = number
  default = 443
}

variable "health_check_protocol" {
  type    = string
  default = "HTTPS"
}

variable "health_check_failure_threshold" {
  type    = number
  default = 3
}

variable "health_check_request_interval" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
