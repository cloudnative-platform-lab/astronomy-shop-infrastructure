# GitOps Module

This module bootstraps GitOps for the EKS cluster.

It deliberately keeps Terraform responsible for only the first step:

- install Argo CD with the official `argo-cd` Helm chart
- create one root Argo CD `Application`

The root application points to:

```text
argocd/appsets/<environment>
```

From there, Argo CD reads the repo-side GitOps YAML and manages:

- `AppProject` resources
- `ApplicationSet` resources that generate one child `Application` per service
- environment wiring
- future Helm values

## Usage

```hcl
module "gitops" {
  source = "../../modules/gitops"

  name                  = local.project
  environment           = local.environment
  repository_url        = var.gitops_repository_url
  root_application_path = "argocd/appsets/${local.environment}"
  target_revision       = "main"
  tags                  = local.common_tags
}
```

`repository_url` must be the dedicated GitOps repository, not the Terraform or application source repository.

The application source repo is referenced from:

```text
argocd/appsets/<environment>/services.yaml
```

## Responsibility Split

Terraform owns infrastructure and bootstrap:

- AWS networking, EKS, IAM, ECR, RDS, Redis, Karpenter, ingress, security, and observability
- Argo CD installation
- root Argo CD application

Argo CD owns Kubernetes delivery:

- environment project boundaries
- app deployment definitions
- continuous reconciliation from Git
- Helm values and workload configuration
