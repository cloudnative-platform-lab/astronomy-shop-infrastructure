variable "name" {
  description = "Platform name used for the root Argo CD application."
  type        = string
}

variable "environment" {
  description = "Environment name such as dev, staging, or prod."
  type        = string
}

variable "argocd_namespace" {
  description = "Namespace where Argo CD is installed."
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Optional argo-cd Helm chart version. Leave null to use the latest chart allowed by the Helm repository."
  type        = string
  default     = null
}

variable "argocd_helm_timeout" {
  description = "Timeout, in seconds, for installing or upgrading the Argo CD Helm release."
  type        = number
  default     = 600
}

variable "argocd_server_service_type" {
  description = "Kubernetes Service type for the Argo CD API server."
  type        = string
  default     = "ClusterIP"
}

variable "argocd_values" {
  description = "Raw YAML values passed to the argo-cd Helm chart."
  type        = list(string)
  default     = []
}

variable "argocd_set_values" {
  description = "Simple Helm set values passed to the argo-cd Helm chart."
  type        = map(string)
  default     = {}
}

variable "install_argocd" {
  description = "Whether Terraform should install Argo CD itself."
  type        = bool
  default     = true
}

variable "create_root_application" {
  description = "Whether Terraform should create the root Argo CD Application that points at argocd/appsets/<environment> in the dedicated GitOps repository."
  type        = bool
  default     = true
}

variable "repository_url" {
  description = "Dedicated GitOps repository containing argocd/, charts/, and helm-values/."
  type        = string
}

variable "target_revision" {
  description = "Git revision, branch, or tag watched by the root Argo CD Application."
  type        = string
}

variable "root_application_path" {
  description = "Path in the dedicated GitOps repository containing the AppProject and ApplicationSet manifests. Defaults to argocd/appsets/<environment>."
  type        = string
  default     = null
}

variable "destination_server" {
  description = "Kubernetes API server destination for the root Argo CD Application."
  type        = string
  default     = "https://kubernetes.default.svc"
}

variable "application_path" {
  description = "Deprecated. Kept so older environment calls do not break; use root_application_path instead."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags kept for module interface consistency."
  type        = map(string)
  default     = {}
}
