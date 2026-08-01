variable "name" { type = string }
variable "environment" { type = string }
variable "domain_name" { type = string }
variable "alb_dns_name" {
  description = "DNS name of the public ALB that CloudFront uses as its origin."
  type        = string

  validation {
    condition     = trimspace(var.alb_dns_name) != ""
    error_message = "alb_dns_name must be the public ALB DNS name when the edge module is enabled."
  }
}
variable "alb_hosted_zone_id" {
  description = "Canonical hosted-zone ID of the ALB."
  type        = string

  validation {
    condition     = !var.manage_origin_dns || trimspace(var.alb_hosted_zone_id) != ""
    error_message = "alb_hosted_zone_id must be the ALB canonical hosted-zone ID when the edge module is enabled."
  }
}
variable "origin_domain_name" {
  description = "Dedicated Route 53 hostname CloudFront uses to reach the ALB, for example origin.dev.shop.example.com."
  type        = string

  validation {
    condition     = trimspace(var.origin_domain_name) != ""
    error_message = "origin_domain_name must be set when the edge module is enabled."
  }
}
variable "route53_zone_id" {
  description = "Hosted-zone ID that owns origin_domain_name."
  type        = string

  validation {
    condition     = !var.manage_origin_dns || trimspace(var.route53_zone_id) != ""
    error_message = "route53_zone_id must be set when the edge module is enabled."
  }
}
variable "manage_origin_dns" {
  description = "Whether Terraform owns the dedicated ALB-origin record. Set false when ExternalDNS owns Ingress hostnames."
  type        = bool
  default     = false
}
variable "certificate_arn" { type = string }
variable "rate_limit_per_5_min" { type = number }
variable "tags" {
  type    = map(string)
  default = {}
}
