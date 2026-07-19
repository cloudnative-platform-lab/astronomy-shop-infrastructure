variable "name" { type = string }
variable "environment" { type = string }
variable "cluster_name" { type = string }
variable "cluster_endpoint" { type = string }
variable "oidc_provider_arn" { type = string }
variable "node_security_group_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "enabled" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "controller_chart_version" {
  type    = string
  default = "1.12.0"
}

variable "nodepool_cpu_limit" {
  type    = string
  default = "100"
}

variable "capacity_types" {
  type    = list(string)
  default = ["on-demand", "spot"]
}

variable "architecture" {
  type    = string
  default = "amd64"
}

variable "allowed_instance_types" {
  type    = list(string)
  default = ["t3.small", "c7i-flex.large", "m7i-flex.large"]

  validation {
    condition = alltrue([
      for instance_type in var.allowed_instance_types : contains([
        "t3.micro",
        "t3.small",
        "c7i-flex.large",
        "m7i-flex.large"
      ], instance_type)
    ])
    error_message = "Karpenter allowed instance types must be one of: t3.micro, t3.small, c7i-flex.large, m7i-flex.large."
  }
}
