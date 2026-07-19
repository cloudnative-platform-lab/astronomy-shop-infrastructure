variable "name" { type = string }
variable "environment" { type = string }
variable "monthly_budget_usd" { type = number }
variable "alert_email" { type = string }

variable "enable_kubecost" {
  type    = bool
  default = true
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
  default = 600
}

variable "tags" {
  type    = map(string)
  default = {}
}
