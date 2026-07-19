variable "name" { type = string }
variable "environment" { type = string }
variable "cluster_name" { type = string }
variable "alert_topic_arn" { type = string }
variable "application_log_group_name" {
  type    = string
  default = ""
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "application_error_threshold" {
  type    = number
  default = 5
}

variable "node_cpu_threshold" {
  type    = number
  default = 80
}

variable "node_memory_threshold" {
  type    = number
  default = 80
}

variable "tags" {
  type    = map(string)
  default = {}
}
