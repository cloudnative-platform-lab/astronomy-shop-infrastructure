terraform {
  backend "s3" {
    key          = "astronomy-shop/bootstrap/dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
