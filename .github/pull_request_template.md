# Pull Request Checklist

## What Changed?

Describe the infrastructure, documentation, module, environment, or GitOps change in this pull request.

## Why?

Explain the reason for the change and the problem it solves.

## Scope

- [ ] Networking
- [ ] EKS / Kubernetes platform
- [ ] Security / IAM
- [ ] CI/CD / GitOps
- [ ] Data services
- [ ] Observability
- [ ] Disaster recovery / backup
- [ ] Cost optimization
- [ ] Documentation only

## Testing Performed

Document the checks performed or reviewed.

- [ ] `terraform fmt -recursive`
- [ ] `terraform validate`
- [ ] `tflint --recursive`
- [ ] `tfsec .`
- [ ] `checkov -d .`
- [ ] Terraform plan reviewed
- [ ] Not run because:

## Deployment Impact

Describe affected environments.

- [ ] dev
- [ ] staging
- [ ] prod
- [ ] no deployment impact

## Risk Review

- [ ] No destructive changes expected
- [ ] Resource replacement reviewed
- [ ] IAM permission changes reviewed
- [ ] Public exposure/security group changes reviewed
- [ ] Cost impact reviewed
- [ ] Monitoring/alerting impact reviewed

## Rollback Plan

Explain how this change can be rolled back if deployment is unhealthy.

For application changes, prefer ArgoCD or Argo Rollouts rollback to a known-good version.

For infrastructure changes, roll back through a reviewed Terraform change instead of manual console edits.

## Notes for Reviewers

Call out anything reviewers should inspect closely, such as sensitive IAM changes, networking changes, production replacements, or accepted security exceptions.
