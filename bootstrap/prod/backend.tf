terraform {
  backend "s3" {
    key          = "astronomy-shop/bootstrap/prod/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
