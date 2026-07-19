variable "name" { type = string }
variable "environment" { type = string }
variable "vpc_cidr" { type = string }
variable "azs" { type = list(string) }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "database_subnet_cidrs" { type = list(string) }
variable "enable_nat_gateway" { type = bool }
variable "single_nat_gateway" { type = bool }
variable "flow_logs_bucket_arn" { type = string }
variable "enable_flow_logs" {
  type    = bool
  default = false
}
variable "flow_logs_retention_days" {
  type    = number
  default = 30
}
variable "interface_endpoint_services" {
  type    = list(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
