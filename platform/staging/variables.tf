variable "aws_region" {
  type    = string
  default = "ap-south-1"
}
variable "bootstrap_state_bucket" {
  type = string
}
variable "bootstrap_state_key" {
  type    = string
  default = "astronomy-shop/bootstrap/staging/terraform.tfstate"
}
variable "bootstrap_state_region" {
  type    = string
  default = "ap-south-1"
}
variable "github_org" {
  type    = string
  default = "cloudnative-platform-lab"
}
variable "github_repo" {
  type    = string
  default = "astronomy-shop-app"
}
variable "gitops_repository_url" {
  type    = string
  default = "git@github.com:cloudnative-platform-lab/astronomy-shop-gitops.git"
}
variable "gitops_repository_ssh_private_key_path" {
  type    = string
  default = ""
}
variable "alert_email" {
  type    = string
  default = ""
}
variable "route53_zone_arns" {
  type    = list(string)
  default = ["arn:aws:route53:::hostedzone/*"]
}
variable "app_namespace" {
  type    = string
  default = ""
}
variable "enable_karpenter" {
  type    = bool
  default = true
}
variable "enable_ingress" {
  type    = bool
  default = true
}
variable "enable_argo_rollouts" {
  type    = bool
  default = true
}
variable "enable_istio" {
  type    = bool
  default = false
}

variable "enable_istio_sidecar_injection" {
  type    = bool
  default = false
}
variable "enable_kubernetes_security" {
  type    = bool
  default = true
}
variable "enable_workload_foundation" {
  type    = bool
  default = true
}
variable "enable_external_secrets" {
  type    = bool
  default = true
}
variable "enable_gitops" {
  type    = bool
  default = true
}
variable "enable_observability" {
  type    = bool
  default = true
}
variable "create_application_ingress" {
  type    = bool
  default = false
}
variable "application_hostname" {
  type    = string
  default = ""
}
variable "alb_certificate_arn" {
  type    = string
  default = ""
}
variable "alb_waf_acl_arn" {
  type    = string
  default = ""
}
variable "create_cert_manager_cluster_issuer" {
  type    = bool
  default = false
}
variable "cert_manager_email" {
  type    = string
  default = ""
}
variable "enable_metrics_server" {
  type    = bool
  default = true
}
variable "enable_alertmanager" {
  type    = bool
  default = true
}
variable "enable_loki" {
  type    = bool
  default = true
}
variable "enable_opentelemetry_collector" {
  type    = bool
  default = true
}
variable "enable_tempo" {
  type    = bool
  default = true
}
variable "enable_observability_persistence" {
  type    = bool
  default = false
}
variable "enable_cloudwatch" {
  type    = bool
  default = true
}
variable "enable_velero" {
  type    = bool
  default = true
}
variable "enable_finops" {
  type    = bool
  default = true
}
variable "enable_kubecost" {
  type    = bool
  default = false
}
variable "cloudwatch_log_retention_days" {
  type    = number
  default = 30
}
variable "enable_kyverno" {
  type    = bool
  default = false
}
variable "kyverno_chart_version" {
  type    = string
  default = null
}
variable "kyverno_values" {
  type    = list(string)
  default = []
}
variable "enable_signed_image_policy" {
  type    = bool
  default = false
}
variable "signed_image_repository_patterns" {
  type    = list(string)
  default = []
}
variable "cosign_subject_regexp" {
  type    = string
  default = "https://github.com/cloudnative-platform-lab/astronomy-shop-app/.github/workflows/.+@refs/heads/main"
}
variable "create_gitops_root_application" {
  type    = bool
  default = true
}
variable "kubecost_chart_version" {
  type    = string
  default = null
}
variable "kubecost_values" {
  type    = list(string)
  default = []
}
variable "app_namespaces" {
  type = map(object({
    enforce                     = optional(string, "baseline")
    audit                       = optional(string, "restricted")
    warn                        = optional(string, "restricted")
    labels                      = optional(map(string), {})
    default_deny_ingress        = optional(bool, true)
    default_deny_egress         = optional(bool, false)
    allow_dns_egress            = optional(bool, true)
    allow_same_namespace_egress = optional(bool, true)
    allow_https_egress          = optional(bool, true)
    allowed_egress_cidrs        = optional(list(string), [])
    allowed_egress_ports        = optional(list(number), [443, 5432, 6379])
  }))
  default = {}
}

variable "enable_falco" {
  type    = bool
  default = false
}
