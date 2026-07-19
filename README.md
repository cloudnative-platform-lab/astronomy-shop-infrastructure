# Astronomy Shop Infrastructure

Private Terraform repository for the Astronomy Shop AWS EKS platform.

## Start here

Follow the beginner guide in the public evidence repository:

```text
astronomy-shop-evidence/docs/HANDS-ON-GUIDE.md
```

Do not start by applying production. Complete dev from beginning to end first.

## Terraform roots

```text
bootstrap/remote-state   Encrypted, versioned S3 state backend
bootstrap/shared         Shared ECR repositories and one GitHub OIDC CI role
bootstrap/dev            Dev AWS and EKS foundation
bootstrap/staging        Staging AWS and EKS foundation
bootstrap/prod           Production AWS and EKS foundation
platform/dev             Dev Kubernetes platform add-ons
platform/staging         Staging Kubernetes platform add-ons
platform/prod            Production Kubernetes platform add-ons
```

## Why shared exists

ECR repositories and the GitHub Actions OIDC provider are account-level delivery resources. Creating them in every environment produces name conflicts and makes image promotion difficult. `bootstrap/shared` creates them once, and every environment deploys the same immutable image digest.

## Safe order

1. `bootstrap/remote-state`
2. `bootstrap/shared`
3. `bootstrap/dev`
4. `platform/dev` with the Argo root Application temporarily disabled
5. Configure the private GitOps deploy key
6. Build and publish application images
7. Enable the dev Argo root Application
8. Verify dev
9. Repeat for staging
10. Repeat for production only after staging passes

## Never commit

- `terraform.tfvars`
- `.terraform/`
- `*.tfstate`
- plan files
- kubeconfig files
- private keys, tokens or passwords

The repository `.gitignore` already excludes these files.
