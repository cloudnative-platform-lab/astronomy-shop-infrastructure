variable "enabled" {
  type    = bool
  default = false
}

variable "namespace" {
  type    = string
  default = "istio-system"
}

variable "application_namespace" {
  type = string
}

variable "base_chart_version" {
  type    = string
  default = "1.22.8"
}

variable "istiod_chart_version" {
  type    = string
  default = "1.22.8"
}

variable "base_values" {
  type    = list(string)
  default = []
}

variable "istiod_values" {
  type    = list(string)
  default = []
}

variable "helm_timeout_seconds" {
  type    = number
  default = 900
}
