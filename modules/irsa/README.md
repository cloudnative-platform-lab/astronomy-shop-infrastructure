# IRSA Module

Creates an IAM role for a Kubernetes service account using EKS IAM Roles for Service Accounts.

Use this for app-level AWS permissions, for example allowing only the `checkout` service to read one Secrets Manager secret or only the `image-provider` service to read one S3 bucket.
