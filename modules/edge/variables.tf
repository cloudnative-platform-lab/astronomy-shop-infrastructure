variable "name" { type = string }
variable "environment" { type = string }
variable "domain_name" { type = string }
variable "alb_dns_name" {
  description = "Custom Route 53 origin hostname that resolves to the ALB, for example origin.shop.example.com."
  type        = string

  validation {
    condition     = trimspace(var.alb_dns_name) != ""
    error_message = "alb_dns_name must be the custom ALB origin hostname when the edge module is enabled."
  }
}
variable "certificate_arn" { type = string }
variable "rate_limit_per_5_min" { type = number }
variable "tags" {
  type    = map(string)
  default = {}
}
