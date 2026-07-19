locals {
  project     = "astronomy-shop"
  environment = "shared"
  services = [
    "cart",
    "checkout",
    "currency",
    "frontend",
    "frontend-proxy",
    "image-provider",
    "payment",
    "product-catalog",
    "recommendation"
  ]

  common_tags = {
    Project       = local.project
    Application   = local.project
    Service       = local.project
    Component     = "shared-delivery"
    Environment   = local.environment
    ManagedBy     = "Terraform"
    TerraformRoot = "bootstrap/shared"
    Repository    = "astronomy-shop-infrastructure"
    Owner         = var.github_org
    Region        = var.aws_region
    CostCenter    = "devsecops-learning"
  }
}
