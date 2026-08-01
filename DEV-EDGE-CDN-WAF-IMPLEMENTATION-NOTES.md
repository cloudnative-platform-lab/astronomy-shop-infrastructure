# Dev Edge, CDN, and WAF Implementation Notes

## Purpose

This is the engineering record for the Dev edge-security work on `2026-08-01`. It records what was created successfully, why each component exists, which commands were only temporary, and the DNS design error that was found and recovered.

## Current stable state

The public Dev application is healthy and intentionally uses this path:

```text
Browser -> Route 53 -> Application Load Balancer -> frontend-proxy -> Astronomy Shop services
```

`dev.astronomy-shop.store` is currently an `A` alias to the Dev ALB. ExternalDNS owns that record. CloudFront and the CloudFront WAF have been created and tested directly, but CloudFront is not currently the permanent public entry point.

## Successfully created resources

| Component | What it is | Why it exists | Owner |
|---|---|---|---|
| Regional ACM certificate | Certificate in `ap-south-1` | Secures the ALB and validates both public and origin hostnames | Terraform/AWS |
| CloudFront ACM certificate | Certificate in `us-east-1` | CloudFront viewer certificates must be in `us-east-1` | Terraform/AWS |
| CloudFront distribution | Global HTTPS edge distribution | Provides the CDN entry point tested before a DNS cutover | Terraform/AWS |
| CloudFront WAF ACL | `CLOUDFRONT` scope web ACL | Applies AWS managed common rules, IP reputation rules, and an IP rate limit | Terraform/AWS |
| `origin.dev.astronomy-shop.store` | Dedicated ALB-origin hostname | Allows CloudFront to use HTTPS to the ALB without using the public hostname as its origin | GitOps, ExternalDNS, Route 53 |
| Updated frontend-proxy Ingress | Kubernetes ALB Ingress | Routes both the public and origin names to Envoy/frontend-proxy | GitOps, Argo CD |

The active regional ALB certificate is:

```text
arn:aws:acm:ap-south-1:241766333730:certificate/e56dc39c-d343-40fd-991a-c2733325964f
```

It is `ISSUED` and includes:

```text
dev.astronomy-shop.store
origin.dev.astronomy-shop.store
```

## Successful verification evidence

### ALB-origin TLS verification

```bash
curl --noproxy '*' -I https://origin.dev.astronomy-shop.store/
```

Expected and observed result: `HTTP/2 200`.

This proves the origin hostname resolves to the ALB, the ALB serves a certificate containing the origin name, the Ingress accepts the host, and the frontend-proxy route succeeds.

### CloudFront direct verification

```bash
curl --noproxy '*' -I "https://$CF_DOMAIN/"
```

Expected and observed result: `HTTP/2 200` with headers similar to:

```text
x-cache: Miss from cloudfront
via: ... CloudFront
x-amz-cf-pop: ...
x-amz-cf-id: ...
```

This proves the tested path was:

```text
Client -> CloudFront + WAF -> origin.dev.astronomy-shop.store -> ALB -> frontend-proxy
```

## Command categories and why they were used

| Command family | What it does in this project | Is it saved? |
|---|---|---|
| `export NAME=value` | Stores a value for the current Bash session, such as an ARN or hostname | No; disappears when the terminal closes |
| `terraform init` | Configures Terraform providers and remote state access | Local Terraform metadata only |
| `terraform plan` | Calculates proposed AWS changes without making them | The plan file is temporary and should not be committed |
| `terraform apply` | Creates or updates AWS resources and records them in remote Terraform state | Yes; AWS resources and S3 state persist |
| `terraform output` | Reads previously saved output values from Terraform state | Read-only |
| `kubectl get` | Reads Kubernetes resources from the EKS API server | Read-only |
| `kubectl annotate` | Changes a live Kubernetes resource | Yes in Kubernetes etcd, but Argo CD can revert it if GitOps differs |
| `kubectl rollout restart` | Restarts a controller so it reconciles configuration again | Temporary operational action |
| `aws acm`, `aws cloudfront`, `aws route53` | Reads or changes AWS service state through AWS APIs | A read command is not saved; a change command persists in AWS |
| `curl` | Sends an HTTP request to validate a live traffic path | Read-only test |
| `git add`, `git commit`, `git push` | Saves source changes and publishes them to GitHub | Yes, after a successful push |
| Python/YAML edit snippets | Make a controlled configuration edit when a simple command is insufficient | Only saved after the edited file is committed and pushed |

## Terraform certificate preparation

Terraform was configured to manage both certificates. The certificate phase was intentionally separate from the CloudFront phase so the ALB could accept the origin hostname before CloudFront used it.

```bash
terraform plan \
  -target=module.alb_certificates \
  -target=module.certificates \
  -out=dev-edge-certificates.tfplan

terraform apply dev-edge-certificates.tfplan
```

The `-target` usage was deliberate for this bootstrap phase. It created the certificate prerequisites without changing public DNS or routing traffic through CloudFront.

## Reproducible successful command sequence

These are the safe commands that produced persistent Dev edge resources. They are kept here so a future implementation has the correct order. Replace the environment hostname and state directory for staging or production.

### 1. Configure Terraform inputs

```bash
export INFRA=/mnt/c/Users/prasa/Documents/Codex/2026-07-23/for/cloudnative-platform-lab/astronomy-shop-infrastructure
export AWS_REGION=ap-south-1
export PUBLIC_HOST=dev.astronomy-shop.store
export ORIGIN_HOST=origin.dev.astronomy-shop.store
export ROOT_ZONE=astronomy-shop.store

cd "$INFRA/bootstrap/dev"
export ZONE_ID="$(aws route53 list-hosted-zones-by-name --dns-name "$ROOT_ZONE." --query "HostedZones[?Name=='$ROOT_ZONE.'] | [0].Id" --output text | sed 's#/hostedzone/##')"
```

Set these persistent Terraform variables in the ignored environment `terraform.tfvars` file:

```hcl
domain_name                         = "dev.astronomy-shop.store"
certificate_subject_alternative_names = ["origin.dev.astronomy-shop.store"]
route53_zone_id                     = "<hosted-zone-id>"
create_certificate_validation_records = true
manage_edge_certificates            = true
enable_edge                          = false
enable_route53                       = false
enable_edge_public_dns_cutover       = false
edge_manage_origin_dns               = false
```

### 2. Create and validate ALB and CloudFront certificates

```bash
terraform init
terraform plan \
  -target=module.alb_certificates \
  -target=module.certificates \
  -out=dev-edge-certificates.tfplan
terraform apply dev-edge-certificates.tfplan

terraform output -raw alb_certificate_arn
terraform output -raw cloudfront_certificate_arn
```

### 3. Update GitOps before enabling CloudFront

The `frontend-proxy` values must contain the new regional ALB certificate ARN and both hosts:

```yaml
ingress:
  hosts:
    - host: dev.astronomy-shop.store
      paths:
        - path: /
          pathType: Prefix
    - host: origin.dev.astronomy-shop.store
      paths:
        - path: /
          pathType: Prefix
```

Commit and push the edited GitOps values. Argo CD applies the Ingress; ExternalDNS creates the ALB alias for the origin hostname. Verify it before continuing:

```bash
curl --noproxy '*' -I https://origin.dev.astronomy-shop.store/
```

The required result is `HTTP/2 200`.

### 4. Create and test CloudFront plus WAF without public DNS cutover

Set these additional Terraform variables:

```hcl
enable_edge                    = true
enable_route53                 = false
enable_edge_public_dns_cutover = false
edge_manage_origin_dns         = false
alb_dns_name                   = "<current ALB DNS name>"
edge_origin_domain_name        = "origin.dev.astronomy-shop.store"
cloudfront_certificate_arn     = "<us-east-1 CloudFront certificate ARN>"
```

Then run:

```bash
terraform plan -out=dev-edge.tfplan
terraform apply dev-edge.tfplan

export CF_DOMAIN="$(terraform output -raw cloudfront_domain_name)"
curl --noproxy '*' -I "https://$CF_DOMAIN/"
```

The required result is `HTTP/2 200` with `via: ... CloudFront` and `x-cache` headers.

### Commands deliberately excluded from the success path

Do not reuse a command that adds `external-dns.alpha.kubernetes.io/target` to the existing `frontend-proxy` Ingress. It caused the documented origin loop. The recovery commands were operational remediation, not a normal deployment procedure.

## Important recovery: the DNS loop

### What failed

The original cutover attempt added this annotation to the single `frontend-proxy` Ingress:

```text
external-dns.alpha.kubernetes.io/target: <CloudFront distribution hostname>
```

That Ingress contained both `dev.astronomy-shop.store` and `origin.dev.astronomy-shop.store`. ExternalDNS applies one target annotation to every hostname on that Ingress, so it changed both names to CloudFront.

CloudFront then used `origin.dev.astronomy-shop.store` as its origin, but that hostname also resolved to CloudFront. This formed a loop:

```text
CloudFront -> origin.dev.astronomy-shop.store -> CloudFront -> ...
```

The visible result was:

```text
HTTP/2 502
x-cache: Error from cloudfront
via: ... CloudFront
```

### How it was recovered

The target annotation was removed, the GitOps template was corrected so that it cannot add that unsafe annotation, Argo CD was refreshed, and ExternalDNS was restarted. Route 53 then returned the public hostname to the ALB alias.

The authoritative final check showed:

```text
ExternalDNS target=
dev.astronomy-shop.store -> A alias -> k8s-dev-frontend-f4e0ec716e-696591853.ap-south-1.elb.amazonaws.com
```

## Required source-control actions

Infrastructure code is not protected until it is committed. Check source state before committing:

```bash
export INFRA=/mnt/c/Users/prasa/Documents/Codex/2026-07-23/for/cloudnative-platform-lab/astronomy-shop-infrastructure
export GITOPS=/mnt/c/Users/prasa/Documents/Codex/2026-07-23/for/cloudnative-platform-lab/real-repositories/astronomy-shop-gitops

git -C "$INFRA" status --short
git -C "$GITOPS" status --short
```

Commit only reviewed source files. Never commit:

```text
terraform.tfvars
*.tfplan
.terraform/
terraform state files
AWS credentials
```

Terraform state is already persisted in the configured S3 backend after a successful `terraform apply`; it is not a replacement for committing Terraform source code.

## Safe future CDN cutover design

Do not use one ExternalDNS target annotation for both the public and origin hostnames.

Before moving the public hostname to CloudFront, choose exactly one DNS ownership model:

1. **Separate Ingress design:** one public Ingress whose ExternalDNS target is CloudFront and one origin Ingress that points directly to the ALB. Both must be deliberately attached to the same ALB.
2. **Terraform-owned public DNS:** exclude the public hostname from ExternalDNS, keep ExternalDNS responsible for only the origin hostname, and let Terraform manage the public Route 53 alias to CloudFront.

In either design, a DNS record must have one owner only: Terraform or ExternalDNS, never both.

## Commands to inspect persistent state

```bash
cd "$INFRA/bootstrap/dev"
terraform state list | grep -E 'module\.(edge|certificates|alb_certificates)'
terraform output

kubectl get ingress frontend-proxy-ingress -n dev -o yaml
kubectl get application frontend-proxy-dev -n argocd
```

These commands read existing state; they do not make changes.
