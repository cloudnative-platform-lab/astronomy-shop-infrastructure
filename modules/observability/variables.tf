variable "name" { type = string }
variable "environment" { type = string }
variable "alert_email" { type = string }
variable "enable_monitoring_stack" {
  type    = bool
  default = true
}
variable "enable_metrics_server" {
  type    = bool
  default = true
}
variable "enable_kube_prometheus_stack" {
  type    = bool
  default = true
}
variable "enable_alertmanager" {
  type    = bool
  default = true
}
variable "enable_loki" {
  type    = bool
  default = false
}
variable "enable_opentelemetry_collector" {
  type    = bool
  default = false
}
variable "enable_tempo" {
  type    = bool
  default = false
}
variable "enable_persistence" {
  type    = bool
  default = false
}
variable "prometheus_retention" {
  type    = string
  default = "7d"
}
variable "metrics_server_chart_version" {
  type    = string
  default = null
}
variable "kube_prometheus_stack_chart_version" {
  type    = string
  default = null
}
variable "loki_stack_chart_version" {
  type    = string
  default = null
}
variable "tempo_chart_version" {
  type    = string
  default = null
}
variable "opentelemetry_collector_chart_version" {
  type    = string
  default = null
}
variable "tags" {
  type    = map(string)
  default = {}
}
