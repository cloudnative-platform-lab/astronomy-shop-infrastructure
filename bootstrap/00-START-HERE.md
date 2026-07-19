# Bootstrap Learning Start Here

This folder creates the AWS foundation for the Astronomy Shop platform.

You do not need to start with the line-by-line guide. That file is only a reference when you want to inspect one exact Terraform line. For learning, start with the folder guides in this order.

1. remote-state/FOLDER-GUIDE.md
   Learn why Terraform needs an S3 bucket and DynamoDB lock table before any environment can be built.

2. dev/FOLDER-GUIDE.md
   Learn the lowest-cost development bootstrap setup.

3. staging/FOLDER-GUIDE.md
   Learn the production-like validation bootstrap setup.

4. prod/FOLDER-GUIDE.md
   Learn the restricted-account production bootstrap setup.

What bootstrap means in this project

Bootstrap means the base AWS infrastructure that must exist before the Kubernetes platform tools and applications can be installed.

The bootstrap layer creates or prepares:

- Terraform remote state foundation.
- VPC and subnets.
- EKS cluster and worker node group.
- ECR repositories for microservice images.
- KMS and secret/security foundations.
- Optional RDS and Redis.
- Optional storage and disaster recovery bucket.
- Optional CloudFront, Route53, and certificates.
- Optional CloudTrail, AWS Config, and backup.
- IAM role wiring for GitHub Actions.

Simple mental model

remote-state prepares where Terraform remembers infrastructure.

dev creates a cheap place to test infrastructure safely.

staging creates a production-like place to validate before prod.

prod creates the strongest version your restricted AWS account can currently support.

How to use these guides

Read the folder guide first.
Then open the Terraform files only when the guide tells you what the file is for.
Do not try to understand every line first.
First understand the purpose of the folder, then the purpose of each file, then the important settings.

Important account facts

AWS account: 241766333730
Region: ap-south-1
Terraform state bucket: astronomy-shop-241766333730-tfstate
DynamoDB lock table: terraform-locks
Allowed EC2 choices used by this project: t3.small for dev, c7i-flex.large for staging, m7i-flex.large for prod
Allowed RDS choice used by this project: db.t3.micro

When to use BOOTSTRAP-CODE-LINE-GUIDE.md

Use that file only after you understand the folder guides.
It is a reference document, not the first learning document.
If you are new, reading it first will feel too detailed because it explains every line mechanically.
