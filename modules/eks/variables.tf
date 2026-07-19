variable "name" { type = string }
variable "environment" { type = string }
variable "cluster_version" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "cluster_endpoint_public_access" {
  type    = bool
  default = true
}
variable "cluster_endpoint_public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
variable "admin_role_arns" {
  type    = list(string)
  default = []
}
variable "node_instance_types" {
  type = list(string)

  validation {
    condition = alltrue([
      for instance_type in var.node_instance_types : contains([
        "t3.micro",
        "t3.small",
        "c7i-flex.large",
        "m7i-flex.large"
      ], instance_type)
    ])
    error_message = "EKS node instance types must be one of: t3.micro, t3.small, c7i-flex.large, m7i-flex.large."
  }
}

variable "node_disk_size" {
  type    = number
  default = 30
}
variable "node_min_size" { type = number }
variable "node_desired_size" { type = number }
variable "node_max_size" { type = number }
variable "enable_ebs_csi_driver" {
  type    = bool
  default = false
}
variable "enable_cloudwatch_observability" {
  type    = bool
  default = false
}

variable "cluster_enabled_log_types" {
  type    = list(string)
  default = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}
variable "tags" {
  type    = map(string)
  default = {}
}
