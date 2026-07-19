module "ecr" {
  source       = "../../modules/ecr"
  name         = local.project
  repositories = local.services
  tags         = local.common_tags
}

module "cicd" {
  source                      = "../../modules/cicd"
  name                        = local.project
  environment                 = local.environment
  github_org                  = var.github_org
  github_repo                 = var.github_app_repository
  create_github_oidc_provider = var.create_github_oidc_provider
  github_oidc_provider_arn    = var.github_oidc_provider_arn
  ecr_repository_arns         = module.ecr.repository_arns
  tags                        = local.common_tags
}
