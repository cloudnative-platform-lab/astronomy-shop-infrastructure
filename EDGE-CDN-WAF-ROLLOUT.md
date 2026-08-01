# CloudFront and WAF rollout

## Ownership

Terraform owns the CloudFront distribution and CloudFront-scope AWS WAF ACL. GitOps owns the `frontend-proxy` Ingress that routes both the public hostname and the origin hostname to the application. In the current platform, ExternalDNS owns both Route 53 records; Terraform must not also manage them.

## Required hostnames

For an environment whose public hostname is `dev.astronomy-shop.store`, use:

- Public hostname: `dev.astronomy-shop.store`
- CloudFront origin hostname: `origin.dev.astronomy-shop.store`

The regional ALB certificate must include both hostnames. The CloudFront viewer certificate must be issued in `us-east-1` and include the public hostname. Never use the regional ALB certificate as the CloudFront viewer certificate.

## Safe order

1. Add the origin hostname to `certificate_subject_alternative_names` and issue or replace the regional ALB certificate.
2. Add the origin hostname to the `hosts` list in the environment's `frontend-proxy-values.yaml`, then let Argo CD reconcile. This prevents an ALB host-rule miss when CloudFront calls the origin.
3. Set `manage_edge_certificates = true` and apply only the certificate modules. Terraform creates a regional ALB certificate and a `us-east-1` CloudFront certificate, with Route 53 validation records.
4. Update the GitOps ingress with the new regional certificate ARN and the origin hostname. Verify the ALB directly using the origin hostname.
5. Set `enable_edge = true`, `edge_manage_origin_dns = false`, and keep `enable_edge_public_dns_cutover = false`. Apply the edge WAF and CloudFront distribution. ExternalDNS creates the origin alias after the GitOps Ingress update. Test the CloudFront distribution hostname.
6. Do not set one ExternalDNS target on an Ingress that contains both the public and CloudFront-origin hostnames. ExternalDNS applies that target to every hostname in that Ingress and would send the CloudFront origin back to CloudFront, creating a 502 loop.
7. Before a public DNS cutover, split the public and origin hosts into independently managed Ingress resources, or transfer public-record ownership to Terraform while ExternalDNS continues to own only the origin record. Keep the public record pointed at the ALB until one of those ownership models is implemented and tested.
8. After traffic is stable, restrict direct ALB access to CloudFront. Do not make that restriction before validation.

## WAF baseline

The module enables AWS Common Rule Set, Amazon IP reputation filtering, and an environment-specific per-IP rate limit. Start with the existing dev/staging limits, observe sampled requests and false positives, then tune production rules and add WAF logging/alerts before enforcing stricter application-specific rules.

## Important boundaries

A `CLOUDFRONT` WAF ACL attaches only to CloudFront. It cannot attach to the ALB. A separate `REGIONAL` WAF ACL would be required if the ALB must be protected directly before CloudFront is enabled.
