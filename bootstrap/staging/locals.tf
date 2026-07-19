locals {
  project     = "astronomy-shop"
  environment = "staging"
  services    = ["cart", "checkout", "currency", "frontend", "frontend-proxy", "image-provider", "product-catalog", "payment", "recommendation"]
  common_tags = {
    Project       = local.project
    Application   = local.project
    Service       = local.project
    Component     = "platform"
    Environment   = local.environment
    ManagedBy     = "Terraform"
    TerraformRoot = "bootstrap/staging"
    Repository    = var.github_repo
    Owner         = var.github_org
    Region        = var.aws_region
    CostCenter    = "devsecops-learning"
  }
}
