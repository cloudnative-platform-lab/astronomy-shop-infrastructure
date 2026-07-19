variable "name" { type = string }
variable "environment" { type = string }

variable "enable_identity_center" {
  type    = bool
  default = false
}

variable "identity_store_id" {
  type    = string
  default = null
}

variable "sso_instance_arn" {
  type    = string
  default = null
}

variable "account_id" {
  type    = string
  default = null
}

variable "permission_sets" {
  type = map(object({
    description      = optional(string, null)
    session_duration = optional(string, "PT8H")
    managed_policies = optional(list(string), [])
  }))
  default = {}
}

variable "group_assignments" {
  type = map(object({
    group_id            = string
    permission_set_name = string
  }))
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
