locals {
  project                 = "astronomy-shop"
  environment             = "dev"
  app_namespace           = local.environment
  effective_app_namespace = var.app_namespace != "" ? var.app_namespace : local.app_namespace
  services                = ["cart", "checkout", "currency", "email", "frontend", "frontend-proxy", "image-provider", "payment", "product-catalog", "recommendation", "shipping"]
  kubernetes_namespace_labels = {
    "app.kubernetes.io/name"       = local.project
    "app.kubernetes.io/part-of"    = local.project
    "app.kubernetes.io/managed-by" = "terraform"
    "environment"                  = local.environment
  }

  app_namespaces = {
    (local.effective_app_namespace) = {
      enforce                     = "baseline"
      audit                       = "restricted"
      warn                        = "restricted"
      labels                      = local.kubernetes_namespace_labels
      default_deny_ingress        = true
      default_deny_egress         = false
      allow_dns_egress            = true
      allow_same_namespace_egress = true
      allow_https_egress          = true
      allowed_egress_cidrs        = [try(data.terraform_remote_state.bootstrap.outputs.vpc_cidr, "10.10.0.0/16")]
      allowed_egress_ports        = [443, 5432, 6379]
    }
  }
  common_tags = {
    Project       = local.project
    Application   = local.project
    Service       = local.project
    Component     = "platform"
    Environment   = local.environment
    ManagedBy     = "Terraform"
    TerraformRoot = "platform/dev"
    Repository    = var.github_repo
    Owner         = var.github_org
    Region        = var.aws_region
    CostCenter    = "devsecops-learning"
  }
}
