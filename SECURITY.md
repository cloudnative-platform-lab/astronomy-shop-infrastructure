# Security Policy

## Supported Scope

This policy covers the Terraform platform code, GitOps bootstrap structure, documentation, scripts, and CI/CD workflow definitions in this repository.

The upstream application source code lives separately:

`https://github.com/Prasanna-1010-AWS/astronomy-shop-app`

## Reporting a Vulnerability

Do not open a public issue for sensitive security findings.

Report privately to the repository owner or security contact with:

- Affected file, module, or environment.
- Description of the issue.
- Potential impact.
- Suggested mitigation if known.
- Whether credentials, secrets, or customer data may be exposed.

For interview/demo use, treat the repository owner as the security contact. In a real organization, replace this with a monitored security email or GitHub private vulnerability reporting.

## Response Targets

| Severity | Example | Target first response | Target mitigation |
| --- | --- | --- | --- |
| Critical | Exposed credential, public write access to data, privilege escalation | Same business day | Immediate containment, then permanent fix |
| High | Overly broad IAM, public ingress to sensitive service, disabled encryption | 1 business day | 3 business days |
| Medium | Missing detective control, weak retention, incomplete logging | 3 business days | Next planned maintenance window |
| Low | Documentation gap or defense-in-depth improvement | 5 business days | Backlog or next release |

## Security Review Areas

Security-sensitive pull requests include changes to:

- IAM policies, roles, trust relationships, and OIDC settings.
- Security groups, NACLs, ingress, WAF, CloudFront, or public DNS.
- KMS keys, Secrets Manager, S3 buckets, RDS, Redis, and backups.
- GitHub Actions workflows and deployment permissions.
- Kubernetes RBAC, service accounts, IRSA, pod security, or network policies.

## Built-In Security Controls

- GitHub Actions OIDC instead of static AWS access keys.
- IRSA for Kubernetes workload identity.
- KMS encryption and Secrets Manager integration.
- WAF, GuardDuty, Security Hub, Inspector, CloudTrail, and AWS Config foundations.
- ECR image scanning and CI/CD scan support.
- Docker base images pinned by digest in the application repository Dockerfiles.
- ECR images signed by digest with Cosign keyless signing in service CI.
- Build provenance and SBOM attestations published for pushed images.
- Production signed-image admission through Kyverno and the Kubernetes security module.
- Pre-commit hooks for key detection, Terraform validation, linting, and security scans.
- Threat model and incident response documentation.

## Security Checks

The expected automated checks are:

- Terraform format and validation.
- TFLint for Terraform quality and provider-specific warnings.
- tfsec for Terraform security misconfiguration scanning.
- Checkov for policy-as-code checks and SARIF upload to GitHub code scanning.
- Pre-commit hooks for local guardrails before a pull request is opened.

Security checks can produce false positives. Accepted exceptions should be documented in the pull request with the risk, compensating control, owner, and review date.

## Vulnerability Response

Security findings should follow this response flow:

```text
Report
  |
  v
Triage
  |
  v
Mitigate
  |
  v
Validate
  |
  v
Document
```

For active compromise or production impact, follow `docs/04-proof-operations-and-troubleshooting.md`.

## Disclosure Expectations

Security fixes should include:

- Clear mitigation summary.
- Affected components.
- Validation performed.
- Follow-up tasks if risk remains.

## Interview Talking Point

The security policy shows that security is treated as an operating process, not only as Terraform resources or scanners.


