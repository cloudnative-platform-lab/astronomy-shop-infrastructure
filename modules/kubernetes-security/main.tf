locals {
  namespace_labels = {
    for namespace, config in var.namespaces : namespace => {
      for key, value in config.labels : key => substr(replace(tostring(value), "/", "-"), 0, 63)
    }
  }
}

resource "kubernetes_namespace_v1" "managed" {
  for_each = var.namespaces

  metadata {
    name = each.key

    labels = merge(
      {
        "pod-security.kubernetes.io/enforce" = each.value.enforce
        "pod-security.kubernetes.io/audit"   = each.value.audit
        "pod-security.kubernetes.io/warn"    = each.value.warn
      },
      local.namespace_labels[each.key]
    )
  }
}

resource "kubernetes_network_policy_v1" "default_deny_ingress" {
  for_each = {
    for namespace, config in var.namespaces : namespace => config
    if config.default_deny_ingress
  }

  metadata {
    name      = "default-deny-ingress"
    namespace = each.key
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }

  depends_on = [kubernetes_namespace_v1.managed]
}

resource "kubernetes_network_policy_v1" "default_deny_egress" {
  for_each = {
    for namespace, config in var.namespaces : namespace => config
    if config.default_deny_egress
  }

  metadata {
    name      = "default-deny-egress"
    namespace = each.key
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]
  }

  depends_on = [kubernetes_namespace_v1.managed]
}

resource "kubernetes_network_policy_v1" "allow_dns_egress" {
  for_each = {
    for namespace, config in var.namespaces : namespace => config
    if config.allow_dns_egress
  }

  metadata {
    name      = "allow-dns-egress"
    namespace = each.key
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }

      ports {
        protocol = "UDP"
        port     = "53"
      }

      ports {
        protocol = "TCP"
        port     = "53"
      }
    }
  }

  depends_on = [kubernetes_namespace_v1.managed]
}

resource "kubernetes_network_policy_v1" "allow_same_namespace_egress" {
  for_each = {
    for namespace, config in var.namespaces : namespace => config
    if config.default_deny_egress && config.allow_same_namespace_egress
  }

  metadata {
    name      = "allow-same-namespace-egress"
    namespace = each.key
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = each.key
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace_v1.managed]
}

resource "kubernetes_network_policy_v1" "allow_configured_egress" {
  for_each = {
    for namespace, config in var.namespaces : namespace => config
    if config.default_deny_egress && length(config.allowed_egress_cidrs) > 0
  }

  metadata {
    name      = "allow-configured-vpc-and-https-egress"
    namespace = each.key
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      dynamic "to" {
        for_each = toset(each.value.allowed_egress_cidrs)
        content {
          ip_block {
            cidr = to.value
          }
        }
      }

      dynamic "ports" {
        for_each = toset(each.value.allowed_egress_ports)
        content {
          protocol = "TCP"
          port     = tostring(ports.value)
        }
      }
    }
  }

  depends_on = [kubernetes_namespace_v1.managed]
}

resource "kubernetes_network_policy_v1" "allow_https_egress" {
  for_each = {
    for namespace, config in var.namespaces : namespace => config
    if config.default_deny_egress && config.allow_https_egress
  }

  metadata {
    name      = "allow-https-egress"
    namespace = each.key
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }

      ports {
        protocol = "TCP"
        port     = "443"
      }
    }
  }

  depends_on = [kubernetes_namespace_v1.managed]
}

resource "helm_release" "falco" {
  count            = var.enable_falco ? 1 : 0
  name             = "falco"
  repository       = "https://falcosecurity.github.io/charts"
  chart            = "falco"
  version          = var.falco_chart_version
  namespace        = var.falco_namespace
  create_namespace = true
  wait             = false
  values           = var.falco_values
}

resource "helm_release" "kyverno" {
  count            = var.enable_kyverno || var.enable_signed_image_policy ? 1 : 0
  name             = "kyverno"
  repository       = "https://kyverno.github.io/kyverno/"
  chart            = "kyverno"
  version          = var.kyverno_chart_version
  namespace        = var.kyverno_namespace
  create_namespace = true
  values           = var.kyverno_values
}

resource "kubernetes_manifest" "require_signed_images" {
  count = var.enable_signed_image_policy ? 1 : 0

  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "require-signed-astronomy-shop-images"
      annotations = {
        "policies.kyverno.io/title"       = "Require signed Astronomy Shop images"
        "policies.kyverno.io/category"    = "Software Supply Chain Security"
        "policies.kyverno.io/description" = "Only admit configured application images when they are deployed by digest and have a keyless Cosign signature from the approved GitHub Actions workflows."
      }
    }
    spec = {
      validationFailureAction = "Enforce"
      background              = false
      failurePolicy           = "Fail"
      webhookTimeoutSeconds   = 30
      rules = [
        {
          name = "verify-cosign-signature"
          match = {
            any = [
              {
                resources = {
                  kinds      = ["Pod"]
                  namespaces = var.signed_image_namespaces
                }
              }
            ]
          }
          verifyImages = [
            {
              imageReferences = var.signed_image_repository_patterns
              required        = true
              mutateDigest    = false
              verifyDigest    = true
              attestors = [
                {
                  count = 1
                  entries = [
                    {
                      keyless = {
                        subjectRegExp = var.cosign_subject_regexp
                        issuer        = var.cosign_issuer
                        rekor = {
                          url = "https://rekor.sigstore.dev"
                        }
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  }

  depends_on = [helm_release.kyverno]
}
