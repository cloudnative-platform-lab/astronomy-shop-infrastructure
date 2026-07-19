variable "namespace" {
  type    = string
  default = "argo-rollouts"
}

variable "chart_version" {
  type    = string
  default = null
}

variable "values" {
  type    = list(string)
  default = []
}

variable "enabled" {
  type    = bool
  default = true
}

variable "enable_dashboard" {
  type    = bool
  default = false
}

variable "dashboard_service_type" {
  type    = string
  default = "ClusterIP"
}
