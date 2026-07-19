variable "name" { type = string }
variable "environment" { type = string }
variable "enable_guardduty" { type = bool }
variable "enable_security_hub" { type = bool }
variable "enable_inspector" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
