# Staging Bootstrap Folder Guide

Folder path

bootstrap/staging

Main purpose

This folder creates the AWS foundation for the staging environment of the Astronomy Shop platform.

It does not deploy the application pods.
It does not install ArgoCD, observability, ingress controllers, Velero, or Kyverno.
Those belong mostly to the platform layer.

This bootstrap folder creates the AWS base that platform depends on.

What this folder creates

- VPC networking.
- Public subnets.
- Private subnets.
- Database subnets.
- NAT gateway behavior depending on settings.
- EKS cluster.
- EKS managed worker node group.
- ECR repositories for microservice images.
- KMS and security foundations.
- Optional IAM Identity Center wiring.
- Optional RDS database.
- Optional Redis cache.
- Optional application storage bucket.
- Optional disaster recovery bucket.
- Optional CloudFront, WAF, certificates, and Route53.
- GitHub Actions IAM role and OIDC wiring.
- Optional CloudTrail, AWS Config, and backup.

Current design for this environment

Environment: staging
VPC CIDR: 10.20.0.0/16
EKS node instance type: c7i-flex.large
NAT behavior: Enabled by example default. The example uses multiple NAT behavior unless you reduce it for quota or cost.
RDS: Enabled by example default using db.t3.micro.
Redis: Enabled by example default using cache.t3.micro.

Staging is the rehearsal environment. It should look close to production, but you can still keep some expensive or account-rejected services disabled.

Files in this folder

backend.tf

This tells Terraform where to store state for this environment bootstrap root.

The key is different for each environment. This is important because dev, staging, and prod must not share the same Terraform state file.

locals.tf

This defines repeated local values such as project name, environment name, service list, and common tags.

The service list is used to create ECR repositories for the application microservices. It must match the staging GitOps values and ArgoCD ApplicationSet service list.

main.tf

This is the main environment definition. It calls reusable modules from the modules folder.

The important module calls are:

- networking creates VPC and subnets.
- security creates KMS and optional security services.
- identity supports IAM Identity Center when enabled.
- ecr creates container repositories.
- eks creates the Kubernetes cluster and node group.
- data_stores creates RDS and Redis when enabled.
- disaster_recovery creates optional replica bucket foundation.
- app_storage creates application S3 storage.
- certificates creates ACM certificates.
- edge creates CloudFront and WAF style edge protection when enabled.
- route53 creates DNS records when enabled.
- cicd creates GitHub Actions AWS access role wiring.
- governance creates audit and compliance foundations.
- backup creates backup vault and backup selection.

outputs.tf

This exposes important values after apply.

Platform uses these values to connect to EKS, networking, ECR, KMS, RDS, Redis, storage, GitHub role, audit resources, and backup resources.

provider.tf

This configures the AWS provider for ap-south-1 and a second provider alias for us-east-1.

The us-east-1 provider exists because CloudFront certificate work often requires ACM in us-east-1.

variables.tf

This declares all configurable inputs for the environment.

The variables allow you to switch optional features on or off without rewriting main.tf.

versions.tf

This pins the Terraform and AWS provider requirements.

terraform.tfvars.example

This gives example values for the environment.

This is where you can see what is enabled or disabled for the environment profile.

How Terraform flows inside this folder

First Terraform reads backend.tf to know where state lives.

Then Terraform reads provider.tf to know which AWS region and provider settings to use.

Then Terraform reads locals.tf to know project name, environment, services, and tags.

Then Terraform reads variables.tf and terraform.tfvars values.

Then Terraform reads main.tf and plans the modules.

Then Terraform prints outputs from outputs.tf after apply succeeds.

What you should change carefully

Change feature flags in terraform.tfvars first.

Examples:

- enable_rds
- enable_redis
- enable_nat_gateway
- single_nat_gateway
- enable_backup
- enable_edge
- enable_route53
- enable_cloudtrail
- enable_config
- enable_guardduty
- enable_security_hub
- enable_inspector

Change instance types only if your AWS account supports them.

Your current allowed EC2 list is limited, so this project uses approved choices.

What not to change casually

Do not change the backend state key unless you understand Terraform state migration.

Do not reuse the same VPC CIDR across environments.

Do not enable GuardDuty, Security Hub, or Inspector until your AWS account accepts those services.

Do not enable multiple NAT gateways without checking EIP quota and cost.

Do not enable Route53 and edge unless you have a real domain and ingress target.

Do not enable RDS or Redis and then expect them to be free.

How this folder connects to platform

Bootstrap creates the EKS cluster and AWS resources.

Platform connects to that EKS cluster and installs Kubernetes-facing tools.

If bootstrap fails, platform should not run.

If EKS nodes are not Ready, platform Helm releases can fail.

If outputs are wrong, platform remote state reading can fail.

Validation after apply

After applying this folder, check:

terraform output
aws eks describe-cluster for this environment
aws eks update-kubeconfig for this environment
kubectl get nodes after kubeconfig is updated
aws ecr describe-repositories for the project repositories
aws rds describe-db-instances if RDS is enabled
aws elasticache describe-replication-groups if Redis is enabled

Common failure points

Backend points to the wrong state bucket.

DynamoDB lock table does not exist.

Existing AWS resources need import or restore.

EKS node group fails because nodes cannot reach the cluster.

NAT or subnet routing is wrong.

AWS account rejects paid security services.

AWS Config recorder already exists in the account and region.

EIP quota is too low for multiple NAT gateways.

Secrets Manager secret may be scheduled for deletion.

How to explain this in an interview

This bootstrap folder creates the AWS foundation for the staging environment. It uses reusable modules for networking, EKS, ECR, security, data stores, storage, CI/CD IAM, governance, backup, and optional edge/DNS. I kept each environment in a separate Terraform state key so dev, staging, and prod can be managed safely. I also tuned the settings for my restricted AWS account, including allowed instance types and disabled services that the account rejected.
