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

variable "enable_application_namespace_injection" {
  type    = bool
  default = false
}

variable "base_chart_version" {
  type    = string
  default = "1.30.3"
}

variable "istiod_chart_version" {
  type    = string
  default = "1.30.3"
}

variable "cni_chart_version" {
  type    = string
  default = "1.30.3"
}

variable "base_values" {
  type    = list(string)
  default = []
}

variable "cni_values" {
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
