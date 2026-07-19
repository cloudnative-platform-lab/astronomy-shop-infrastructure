locals {
  argocd_namespace      = var.argocd_namespace
  root_application      = "${var.name}-${var.environment}-root"
  root_application_path = coalesce(var.root_application_path, var.application_path, "argocd/appsets/${var.environment}")
}

resource "helm_release" "argocd" {
  count            = var.install_argocd ? 1 : 0
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = local.argocd_namespace
  create_namespace = true
  wait             = true
  timeout          = var.argocd_helm_timeout
  values           = var.argocd_values

  dynamic "set" {
    for_each = var.argocd_set_values

    content {
      name  = set.key
      value = set.value
    }
  }

  set {
    name  = "server.service.type"
    value = var.argocd_server_service_type
  }
}

resource "kubernetes_manifest" "root_application" {
  count = var.install_argocd && var.create_root_application ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = local.root_application
      namespace = local.argocd_namespace
      labels = {
        environment  = var.environment
        "managed-by" = "terraform"
      }
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.repository_url
        targetRevision = var.target_revision
        path           = local.root_application_path
        directory = {
          recurse = true
        }
      }
      destination = {
        server    = var.destination_server
        namespace = local.argocd_namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }

  depends_on = [helm_release.argocd]
}
