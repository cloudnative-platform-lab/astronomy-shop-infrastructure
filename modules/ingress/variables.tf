variable "name" { type = string }
variable "environment" { type = string }
variable "cluster_name" { type = string }
variable "vpc_id" { type = string }
variable "oidc_provider_arn" { type = string }
variable "route53_zone_arns" {
  type    = list(string)
  default = ["arn:aws:route53:::hostedzone/*"]
}
variable "create_application_ingress" {
  type    = bool
  default = false
}
variable "application_namespace" {
  type    = string
  default = "astronomy-shop"
}
variable "application_hostname" {
  type    = string
  default = ""
}
variable "application_service_name" {
  type    = string
  default = "frontend-proxy"
}
variable "application_service_port" {
  type    = number
  default = 80
}
variable "alb_certificate_arn" {
  type    = string
  default = ""
}
variable "alb_waf_acl_arn" {
  type    = string
  default = ""
}
variable "alb_healthcheck_path" {
  type    = string
  default = "/"
}
variable "aws_load_balancer_controller_chart_version" {
  type    = string
  default = "1.8.1"
}
variable "external_dns_chart_version" {
  type    = string
  default = "1.14.5"
}
variable "cert_manager_chart_version" {
  type    = string
  default = "v1.15.3"
}
variable "create_cluster_issuer" {
  type    = bool
  default = false
}
variable "cluster_issuer_email" {
  type    = string
  default = ""
}
variable "cluster_issuer_server" {
  type    = string
  default = "https://acme-v02.api.letsencrypt.org/directory"
}
variable "tags" {
  type    = map(string)
  default = {}
}
