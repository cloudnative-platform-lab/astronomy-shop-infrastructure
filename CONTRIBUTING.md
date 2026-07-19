# Contributing

This guide documents the expected workflow for contributing infrastructure, documentation, and GitOps-related changes.

## Branch Flow

```text
feature branch
  |
  v
pull request
  |
  v
automated checks
  |
  v
review and approval
  |
  v
merge to main
```

Use small pull requests where possible. Separate unrelated Terraform, GitOps, and documentation changes.

Recommended branch names:

- `feature/<short-description>` for new modules or platform capabilities.
- `fix/<short-description>` for corrective changes.
- `docs/<short-description>` for documentation-only updates.
- `security/<short-description>` for security hardening or vulnerability fixes.

Production-impacting changes should move through dev, staging, and prod in order unless an incident commander approves an emergency path.

## Pull Request Expectations

Every pull request should explain:

- What changed.
- Why the change is needed.
- Which environments are affected.
- What testing or review was performed.
- Whether the change affects security, cost, reliability, or public exposure.
- How to roll back if the change is unhealthy.

Use `.github/pull_request_template.md` for the standard checklist.

## Testing Expectations

Expected checks for Terraform changes:

```bash
terraform fmt -recursive
terraform -chdir=bootstrap/remote-state init -backend=false
terraform -chdir=bootstrap/remote-state validate
tflint --recursive
tfsec .
checkov -d .
```

Environment roots should be validated independently where applicable:

```bash
terraform -chdir=bootstrap/dev init -backend=false
terraform -chdir=bootstrap/dev validate
terraform -chdir=platform/dev init -backend=false
terraform -chdir=platform/dev validate
terraform -chdir=bootstrap/staging init -backend=false
terraform -chdir=bootstrap/staging validate
terraform -chdir=platform/staging init -backend=false
terraform -chdir=platform/staging validate
terraform -chdir=bootstrap/prod init -backend=false
terraform -chdir=bootstrap/prod validate
terraform -chdir=platform/prod init -backend=false
terraform -chdir=platform/prod validate
```

See `tests/00-read-this-first.md` for the full quality gate strategy. The required Terraform CI workflow is `.github/workflows/terraform-ci.yml`.

If a check cannot be run locally, document the reason in the pull request and rely on CI or reviewer inspection. Do not hide skipped checks.

## Review Guidelines

Reviewers should pay special attention to:

- IAM permissions and trust policies.
- Public ingress, security groups, and network routing.
- Data store encryption, backup, and retention settings.
- Terraform resource replacements.
- Cost-impacting changes such as NAT, node groups, RDS, and logging volume.
- Changes that affect production promotion or rollback.

Minimum review expectations:

- One platform approval for all Terraform changes.
- Security approval for IAM, public exposure, encryption, CI/CD permissions, and runtime security changes.
- Data/platform approval for RDS, Redis, S3, backup, and retention changes.
- Explicit production approval for prod environment changes.

## Documentation Expectations

Update documentation when a change affects:

- Architecture.
- Security model.
- Deployment or promotion flow.
- Runbooks.
- Disaster recovery.
- Observability.
- Cost optimization.
- SLOs or incident response.

## Release Discipline

Update `CHANGELOG.md` for meaningful changes. Use the `Unreleased` section during development, then create a dated release entry when a platform milestone is ready.

## Interview Talking Point

The contribution process shows how infrastructure changes move through review, automated checks, risk assessment, and rollback planning before production promotion.

