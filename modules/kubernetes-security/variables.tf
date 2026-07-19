variable "namespaces" {
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

variable "enable_kyverno" {
  type    = bool
  default = false
}

variable "kyverno_namespace" {
  type    = string
  default = "kyverno"
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

variable "signed_image_namespaces" {
  type    = list(string)
  default = []
}

variable "signed_image_repository_patterns" {
  type    = list(string)
  default = []
}

variable "cosign_issuer" {
  type    = string
  default = "https://token.actions.githubusercontent.com"
}

variable "cosign_subject_regexp" {
  type    = string
  default = "https://github.com/Prasanna-1010-AWS/astronomy-shop-app/.github/workflows/.+@refs/heads/main"
}

variable "falco_namespace" {
  type    = string
  default = "falco"
}

variable "falco_chart_version" {
  type    = string
  default = null
}

variable "falco_values" {
  type    = list(string)
  default = []
}
