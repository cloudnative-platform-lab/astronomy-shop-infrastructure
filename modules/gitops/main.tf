locals {
  argocd_namespace      = var.argocd_namespace
  root_application      = "${var.name}-${var.environment}-root"
  root_application_path = coalesce(var.root_application_path, var.application_path, "argocd/appsets/${var.environment}")
  uses_ssh_repository   = startswith(var.repository_url, "git@")
  manages_repository_credentials = local.uses_ssh_repository && var.repository_ssh_private_key != null
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
  values = concat(var.argocd_values, [yamlencode({
    configs = {
      cm = {
        "resource.customizations.health.argoproj.io_Rollout" = <<-LUA
          hs = {}
          if obj.status ~= nil then
            if obj.status.phase == "Healthy" then
              hs.status = "Healthy"
              hs.message = "Rollout is healthy"
              return hs
            end
            if obj.status.phase == "Degraded" then
              hs.status = "Degraded"
              hs.message = obj.status.message or "Rollout is degraded"
              return hs
            end
          end
          hs.status = "Progressing"
          hs.message = "Waiting for Argo Rollout to become healthy"
          return hs
        LUA
      }
    }
  })])

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

resource "kubernetes_secret_v1" "repository_credentials" {
  count = var.install_argocd && local.manages_repository_credentials ? 1 : 0

  metadata {
    name      = "astronomy-shop-gitops-repository"
    namespace = local.argocd_namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type          = "git"
    url           = var.repository_url
    sshPrivateKey = var.repository_ssh_private_key
  }

  type       = "Opaque"
  depends_on = [helm_release.argocd]
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

  depends_on = [helm_release.argocd, kubernetes_secret_v1.repository_credentials]

  lifecycle {
    precondition {
      condition     = !local.uses_ssh_repository || local.manages_repository_credentials
      error_message = "An SSH GitOps repository requires repository_ssh_private_key so Argo CD can render and sync applications."
    }
  }
}
