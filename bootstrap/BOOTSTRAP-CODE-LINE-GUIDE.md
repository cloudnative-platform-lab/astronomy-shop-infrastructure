# Bootstrap Code Learning Guide

This file explains the bootstrap Terraform code in a simple learning order.

The old line-by-line style was too hard to study because it forced you to read Terraform like a dictionary. This version teaches the same code by purpose, folder, file, and block. That is how a DevOps engineer normally learns infrastructure code.

Start here when you want to understand the bootstrap code.

## Quick Learning Path

If you have only 20 minutes, read only these sections first:

1. What Bootstrap Means In This Project.
2. Folder Order.
3. File Types You See In Every Bootstrap Folder.
4. How To Understand main.tf.
5. Environment Differences.
6. What You Can Safely Change First.
7. What You Should Not Change Casually.

After that, open one real folder guide:

- remote-state/FOLDER-GUIDE.md when learning remote backend.
- dev/FOLDER-GUIDE.md when learning the cheapest environment.
- staging/FOLDER-GUIDE.md when learning production-like validation.
- prod/FOLDER-GUIDE.md when learning the production profile.

## How To Read This File

Read this file in this order:

1. Understand what bootstrap means.
2. Understand the folder order.
3. Understand what each file type does.
4. Understand the common Terraform blocks.
5. Understand the modules in main.tf.
6. Understand the difference between dev, staging, and prod.
7. Learn what you can safely change.
8. Learn what you should not change casually.

Do not start by memorizing every line.

First understand why the line exists.
Then understand which file owns it.
Then understand what happens if you change it.

## What Bootstrap Means In This Project

Bootstrap means the AWS foundation that must exist before the Kubernetes platform and application deployment can work.

In this project, bootstrap creates or prepares:

- Terraform remote state.
- VPC networking.
- Public, private, and database subnets.
- NAT gateway behavior.
- EKS cluster.
- EKS worker node group.
- ECR repositories for application images.
- KMS and security foundation.
- Optional RDS database.
- Optional Redis cache.
- Optional application storage bucket.
- Optional disaster recovery bucket.
- Optional CloudFront and WAF edge layer.
- Optional Route53 DNS.
- Optional ACM certificates.
- GitHub Actions AWS IAM role wiring.
- Optional CloudTrail, AWS Config, and backup.

Platform comes after bootstrap.

Platform installs Kubernetes-facing tools such as ArgoCD, ingress controllers, observability, Kyverno, External Secrets, Karpenter, and Velero.

If bootstrap is broken, platform will usually fail.

## Folder Order

Read and implement bootstrap in this order.

1. bootstrap/remote-state

This creates the S3 bucket and DynamoDB lock table for Terraform state.

Run this before dev, staging, or prod.

2. bootstrap/dev

This creates the low-cost development AWS foundation.

Use it for learning, testing, and safe validation.

3. bootstrap/staging

This creates a production-like environment.

Use it to test changes before production.

4. bootstrap/prod

This creates the strongest version your restricted AWS account can currently support.

Use it only after you understand dev and staging.

## Why Remote State Exists

Terraform needs state.

State tells Terraform what it already created in AWS.

If state is only on your laptop, it can be lost or corrupted. Remote state puts that record in S3.

The DynamoDB table prevents two Terraform runs from changing the same state at the same time.

In your project:

State bucket: astronomy-shop-241766333730-tfstate
Lock table: terraform-locks
Region: ap-south-1

Remote state is not application storage.
DynamoDB lock table is not application data.
They exist only for Terraform safety.

## File Types You See In Every Bootstrap Folder

### backend.tf

This file tells Terraform where to store the state file.

The important idea is the state key.

Each environment has its own state key:

- dev has a dev bootstrap state path.
- staging has a staging bootstrap state path.
- prod has a prod bootstrap state path.

This prevents one environment from overwriting another environment.

Do not casually change backend.tf after resources exist.
Changing backend configuration can require state migration or reconfiguration.

### provider.tf

This file tells Terraform how to talk to AWS.

The normal AWS provider uses ap-south-1.

There is also a us-east-1 provider alias.

That exists because CloudFront-related ACM certificates must be handled in us-east-1.

### locals.tf

This file stores repeated local values.

It defines:

- Project name.
- Environment name.
- Service list.
- Common AWS tags.

The service list is important because it drives ECR repository creation.

In this project, the service list has nine microservices. Those names must stay aligned with GitHub Actions, GitOps values, and ArgoCD ApplicationSets.

The common tags are important because they help identify ownership, environment, region, repository, cost center, and Terraform root.

### variables.tf

This file declares inputs.

Variables let you change behavior without rewriting main.tf.

Examples:

- enable_rds controls whether RDS is created.
- enable_redis controls whether Redis is created.
- enable_nat_gateway controls NAT creation.
- enable_backup controls backup creation.
- enable_edge controls CloudFront and WAF style edge resources.
- enable_route53 controls DNS resources.
- enable_guardduty, enable_security_hub, and enable_inspector control AWS security services.

Variables are the knobs of the environment.

### terraform.tfvars.example

This file shows example values for the environment.

This is usually the safest place to understand what is enabled or disabled.

In your project, this file also reflects account restrictions.

For example, GuardDuty, Security Hub, and Inspector are set false because your account rejected those services.

### main.tf

This is the main design file.

It calls reusable modules from the modules folder.

You should read main.tf as a list of building blocks:

- networking
- security
- identity
- ecr
- eks
- data_stores
- disaster_recovery
- app_storage
- certificates
- edge
- route53
- cicd
- governance
- backup

### outputs.tf

This file prints useful values after Terraform apply.

Outputs are important because the platform layer needs bootstrap results.

Examples:

- EKS cluster name.
- EKS endpoint.
- VPC ID.
- subnet IDs.
- KMS key ARN.
- ECR repository URLs.
- RDS ARN.
- Redis ARN.
- storage bucket name.
- GitHub Actions role ARN.

### versions.tf

This file controls Terraform and provider version expectations.

It helps avoid surprises from using a very old Terraform version or a future provider version with breaking changes.

## How To Understand main.tf

Do not read main.tf as random code.

Read it as a sequence of infrastructure layers.

### 1. networking module

This creates the network foundation.

It controls:

- VPC CIDR.
- Availability Zones.
- Public subnets.
- Private subnets.
- Database subnets.
- NAT gateway behavior.
- Flow log bucket wiring.

Why it matters:

Everything else depends on networking.

EKS needs subnets.
RDS needs database subnets.
Redis needs database subnets.
Load balancers need public subnets.
Private workloads need private subnets.

If networking is wrong, EKS nodes may fail to join the cluster.

### 2. security module

This creates security foundation resources.

It includes KMS and optional security services.

Why it matters:

KMS is used by other modules for encryption.

GuardDuty, Security Hub, and Inspector are useful in company environments, but your AWS account rejected them earlier. That is why your tfvars examples keep them disabled.

### 3. identity module

This supports IAM Identity Center.

Why it matters:

Companies often use SSO instead of long-lived IAM users.

In your project, this is optional because it needs real Identity Center IDs before it can work.

### 4. ecr module

This creates container repositories.

Why it matters:

Your microservices need image repositories before CI/CD can push images.

The service list comes from locals.tf.

Services include:

- cart
- checkout
- currency
- frontend
- frontend-proxy
- image-provider
- product-catalog
- payment
- recommendation

### 5. eks module

This creates the Kubernetes cluster.

Why it matters:

The platform layer depends on EKS.

If EKS is not ready, Helm, ArgoCD, observability, Kyverno, and Velero can fail.

Important EKS settings:

cluster_version sets the Kubernetes version.

vpc_id connects EKS to the VPC.

private_subnet_ids tells EKS where to place worker nodes.

cluster_endpoint_public_access controls whether the EKS API can be reached publicly.

node_instance_types controls the EC2 type used by worker nodes.

node_min_size, node_desired_size, and node_max_size control node group size.

cluster_enabled_log_types controls EKS control plane logging.

enable_ebs_csi_driver is disabled in staging and prod because the add-on previously timed out in your account.

### 6. data_stores module

This creates RDS and Redis when enabled.

Why it matters:

RDS is the relational database foundation.

Redis supports cart, cache, and fast temporary data behavior.

In your restricted account:

RDS uses db.t3.micro.

Redis uses cache.t3.micro.

RDS Multi-AZ is disabled to control cost and because this is a restricted account profile.

A company-grade production setup would normally use stronger database sizing, Multi-AZ, stronger backup retention, connection pooling, and tested failover.

### 7. disaster_recovery module

This creates optional DR storage foundation.

Why it matters:

Production systems need a recovery story.

In your current profile, DR replication is usually disabled unless you intentionally enable it.

### 8. app_storage module

This creates application S3 storage.

Why it matters:

The application may need object storage for uploads, generated assets, or service data.

It can optionally replicate to the DR bucket.

### 9. certificates module

This creates ACM certificates.

Why it matters:

HTTPS needs certificates.

CloudFront certificates need us-east-1.

That is why provider.tf has the us_east_1 provider alias.

### 10. edge module

This creates edge layer resources when enabled.

It can include CloudFront and WAF style protection.

Why it matters:

The edge layer improves public traffic handling, caching, and rate protection.

In your current examples, edge is disabled until you provide real domain and ALB values.

### 11. route53 module

This creates DNS records when enabled.

Why it matters:

Users need a domain name to reach the application cleanly.

Route53 depends on edge being enabled in this design.

### 12. cicd module

This creates GitHub Actions AWS role wiring.

Why it matters:

GitHub Actions needs permission to push images and interact with AWS safely.

The GitHub OIDC provider can be reused if it already exists.

You already hit an OIDC duplicate error earlier, so this wiring matters.

### 13. governance module

This creates audit and governance resources.

It can include CloudTrail and AWS Config.

Why it matters:

Companies need audit trails and configuration visibility.

Your account has AWS Config recorder limits, so enable_config must be handled carefully.

### 14. backup module

This creates AWS Backup resources when enabled.

Why it matters:

RDS should have a backup story.

Redis was excluded from AWS Backup selection because AWS Backup rejected ElastiCache ARN selection in your account.

## Environment Differences

### Dev

Purpose:

Low-cost learning and testing.

VPC CIDR:

10.10.0.0/16

Node type:

t3.small

Node count:

Minimum 1, desired 1, maximum 1.

RDS:

Disabled in the example.

Redis:

Disabled in the example.

NAT:

Disabled in the example.

Why dev is small:

Dev is for safe testing. It should not spend too much money.

### Staging

Purpose:

Production-like validation before prod.

VPC CIDR:

10.20.0.0/16

Node type:

c7i-flex.large

Node count:

Minimum 1, desired 1, maximum 2.

RDS:

Enabled in the example.

Redis:

Enabled in the example.

NAT:

Enabled in the example.

Why staging is stronger than dev:

Staging should test realistic behavior before production.

### Prod

Purpose:

Restricted-account production profile.

VPC CIDR:

10.30.0.0/16

Node type:

m7i-flex.large

Node count:

Minimum 1, desired 1, maximum 2.

RDS:

Enabled in the example.

Redis:

Enabled in the example.

NAT:

Enabled with single NAT behavior in the example.

Why prod is still restricted:

This production profile is designed around your account limits.

It is not the same as a large company production setup.

A company production setup would normally use multiple AWS accounts, stronger databases, stronger Redis, private endpoint controls, stronger secrets process, stronger security services, tested failover, and larger capacity.

## Important Feature Flags

### enable_nat_gateway

This controls whether private subnets can reach the internet through NAT.

If NAT is disabled, private nodes may not reach AWS APIs or public internet unless other routing exists.

NAT costs money and uses Elastic IPs.

Your account already hit EIP quota issues, so NAT settings must be handled carefully.

### single_nat_gateway

This controls whether one NAT gateway is shared or multiple NAT gateways are used.

Single NAT is cheaper.

Multiple NAT gateways are more resilient but cost more and require more Elastic IPs.

### enable_rds

This controls whether RDS is created.

Enable it when the environment needs a database.

In this project, staging and prod examples enable RDS.

### enable_redis

This controls whether Redis is created.

Enable it when cart/cache behavior needs Redis.

In this project, staging and prod examples enable Redis.

### enable_guardduty

This controls GuardDuty.

Your account previously rejected it with a subscription error.

Keep it disabled until the account supports it.

### enable_security_hub

This controls Security Hub.

Your account previously rejected it with a subscription error.

Keep it disabled until the account supports it.

### enable_inspector

This controls AWS Inspector.

Your account previously rejected it with a subscription error.

Keep it disabled until the account supports it.

### enable_cloudtrail

This controls CloudTrail.

CloudTrail gives audit history for AWS API activity.

Staging and prod can enable it when you want stronger audit evidence.

### enable_config

This controls AWS Config.

Your account can only have one customer-managed config recorder per region.

Do not enable it in multiple places without planning.

### enable_backup

This controls AWS Backup resources.

In this project, backup is mainly for RDS.

Redis is not selected because AWS Backup rejected ElastiCache ARN selection.

### enable_edge

This controls edge resources such as CloudFront and WAF style protection.

Keep it disabled until you have domain and ALB details ready.

### enable_route53

This controls DNS records.

Route53 should be enabled only when domain and hosted zone choices are clear.

## What You Can Safely Change First

Start with terraform.tfvars values.

That is safer than editing main.tf.

Good first changes:

- Enable or disable RDS.
- Enable or disable Redis.
- Choose NAT behavior.
- Add EKS admin role ARNs.
- Add a real GitHub OIDC provider ARN.
- Add domain values only when you are ready for edge and DNS.
- Keep rejected security services disabled until AWS allows them.

## What You Should Not Change Casually

Do not casually change backend.tf.

Backend changes can affect Terraform state location.

Do not casually change VPC CIDR after resources exist.

Network CIDR changes can force replacement of large infrastructure.

Do not casually change EKS cluster name or environment name.

Those names connect many resources together.

Do not casually increase node counts.

Your account has cost and quota limits.

Do not enable all optional services at once.

Enable in layers and validate after each layer.

Do not claim a feature is production proven just because it exists in Terraform.

Prove it with commands, screenshots, load tests, or recovery tests.

## How Bootstrap Connects To Platform

Bootstrap creates the AWS foundation.

Platform uses bootstrap outputs.

Example flow:

Bootstrap creates EKS.
Platform connects to EKS.
Platform installs ArgoCD.
Platform installs ingress.
Platform installs observability.
Platform installs policy and backup tools.
GitOps deploys applications.

If EKS is unreachable, platform fails.

If nodes are not Ready, Helm releases may fail.

If outputs are wrong, platform cannot wire itself correctly.

## Common Errors And What They Mean

BucketAlreadyOwnedByYou

The S3 bucket already exists in your account.

This usually means Terraform state and AWS reality need alignment.

ResourceNotFoundException for DynamoDB lock table

Terraform backend is trying to use a lock table that does not exist.

Create remote-state first.

NoSuchBucket

Terraform backend is pointing to a bucket that does not exist or still has a placeholder name.

Backend configuration changed

Terraform detected backend settings changed.

Use reconfigure or migrate-state depending on whether you are moving existing state.

EKS node creation failure

Worker nodes launched but did not join the cluster.

Check subnet routing, NAT, security groups, node IAM, and endpoint access.

GuardDuty, Security Hub, or Inspector subscription error

Your account does not support that service yet.

Keep the feature disabled.

AWS Config recorder limit error

Only one customer-managed recorder is allowed per account and region.

Enable Config carefully.

EIP limit reached

Too many Elastic IPs are allocated or requested.

Reduce NAT gateway count or release unused EIPs.

## How To Study The Actual Terraform Files

Use this order:

1. Open locals.tf.

Understand project name, environment name, service list, and tags.

2. Open variables.tf.

Understand what can be changed through inputs.

3. Open terraform.tfvars.example.

Understand what this environment actually enables.

4. Open main.tf.

Read each module as one infrastructure building block.

5. Open outputs.tf.

Understand what other layers will need from bootstrap.

6. Open provider.tf.

Understand AWS region and us-east-1 alias.

7. Open backend.tf.

Understand where Terraform state is stored.

8. Open versions.tf.

Understand Terraform and provider version expectations.

## How To Explain Bootstrap In An Interview

Use this answer:

The bootstrap layer creates the AWS foundation for each environment. I separated remote-state, dev, staging, and prod so Terraform state is isolated and environment changes can be promoted safely. Remote-state creates the S3 backend and DynamoDB lock table. Each environment bootstrap creates networking, EKS, ECR, security, optional data stores, storage, CI/CD IAM, governance, backup, and optional edge or DNS resources. I tuned the design for a restricted AWS account by using allowed EC2 and RDS types, controlling NAT costs, and disabling services the account rejected until they can be enabled safely.

## The Simple Memory Version

Remote-state answers: Where does Terraform remember things?

Networking answers: Where will AWS resources live?

EKS answers: Where will Kubernetes run?

ECR answers: Where will container images live?

Security answers: How are encryption and security foundations handled?

Data stores answer: Where do database and cache live?

Storage answers: Where does app object storage live?

CI/CD answers: How does GitHub Actions access AWS?

Governance answers: How do we audit and track changes?

Backup answers: How do we recover important resources?

Edge and DNS answer: How do users reach the application through a domain?
## Study Checklist

Use this checklist after reading the guide.

I can explain why remote-state must run first.

I can explain the difference between bootstrap and platform.

I can explain what backend.tf does.

I can explain why provider.tf has ap-south-1 and us-east-1.

I can explain why locals.tf contains project, environment, services, and tags.

I can explain why variables.tf is where feature switches are declared.

I can explain why terraform.tfvars.example shows the environment profile.

I can explain main.tf as a set of modules instead of random code.

I can explain why outputs.tf matters for the platform layer.

I can explain the difference between dev, staging, and prod capacity.

I can explain why some paid security services are disabled in this account.

I can explain why RDS and Redis are enabled in staging/prod but not dev by default.

I can explain why NAT gateway settings affect cost and EIP quota.

I can explain what I would change first and what I would not change casually.


