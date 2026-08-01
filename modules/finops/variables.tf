variable "name" { type = string }
variable "environment" { type = string }
variable "monthly_budget_usd" { type = number }
variable "alert_email" { type = string }

variable "enable_kubecost" {
  type    = bool
  default = true
}

variable "enable_persistence" {
  type    = bool
  default = false
}

variable "kubecost_namespace" {
  type    = string
  default = "kubecost"
}

variable "kubecost_chart_version" {
  type    = string
  default = null
}

variable "kubecost_values" {
  type    = list(string)
  default = []
}

variable "kubecost_helm_timeout" {
  type    = number
  default = 1800
}

variable "tags" {
  type    = map(string)
  default = {}
}
