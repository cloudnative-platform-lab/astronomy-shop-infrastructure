provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
  default_tags { tags = local.common_tags }
}

data "terraform_remote_state" "bootstrap" {
  backend = "s3"
  config = {
    bucket = var.bootstrap_state_bucket
    key    = var.bootstrap_state_key
    region = var.bootstrap_state_region
    profile = var.aws_profile
  }
}

data "aws_eks_cluster" "this" {
  name = data.terraform_remote_state.bootstrap.outputs.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = concat(
        var.aws_profile == null ? [] : ["--profile", var.aws_profile],
        ["eks", "get-token", "--cluster-name", data.terraform_remote_state.bootstrap.outputs.cluster_name, "--region", var.aws_region]
      )
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = concat(
      var.aws_profile == null ? [] : ["--profile", var.aws_profile],
      ["eks", "get-token", "--cluster-name", data.terraform_remote_state.bootstrap.outputs.cluster_name, "--region", var.aws_region]
    )
  }
}
