# Remote State Bootstrap

This small stack creates the versioned, encrypted S3 bucket used by all Terraform backends. Current roots use S3 native lock files (`use_lockfile = true`). The DynamoDB lock table is optional only for older Terraform clients.

Run it only after choosing a globally unique bucket name and only when you are ready to use AWS:

```bash
terraform init
terraform plan -var="state_bucket_name=<unique-bucket-name>"
terraform apply
```

Then initialize each root with the bucket output. The backend files already contain the state key, Region, encryption, and S3 locking configuration.

- `bootstrap/dev/backend.tf`
- `bootstrap/staging/backend.tf`
- `bootstrap/prod/backend.tf`
- `platform/dev/backend.tf`
- `platform/staging/backend.tf`
- `platform/prod/backend.tf`

Keep this bootstrap state file private. After the backend exists, the main environment states should live in S3.
