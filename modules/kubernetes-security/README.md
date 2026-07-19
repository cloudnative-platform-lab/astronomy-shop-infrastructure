# Kubernetes Security Module

Creates baseline Kubernetes security controls:

- namespaces with Pod Security Standards labels
- optional default-deny ingress NetworkPolicies
- optional default-deny egress NetworkPolicies
- optional DNS egress allow policy
- optional Falco runtime security installation
- optional Kyverno installation
- optional Cosign keyless signed-image admission policy for application namespaces

Use this module for platform-level guardrails. Application-specific NetworkPolicies can still live in GitOps with the application manifests.

When `enable_signed_image_policy` is true, Kyverno enforces that matching images are deployed by digest and have a Cosign signature issued by the configured GitHub Actions OIDC identity.
