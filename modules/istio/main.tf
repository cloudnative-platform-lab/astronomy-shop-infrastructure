resource "helm_release" "base" {
  count            = var.enabled ? 1 : 0
  name             = "istio-base"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "base"
  version          = var.base_chart_version
  namespace        = var.namespace
  create_namespace = true
  wait             = true
  timeout          = var.helm_timeout_seconds
  values           = var.base_values
}

resource "helm_release" "cni" {
  count            = var.enabled ? 1 : 0
  name             = "istio-cni"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "cni"
  version          = var.cni_chart_version
  namespace        = var.namespace
  create_namespace = true
  wait             = true
  timeout          = var.helm_timeout_seconds
  values           = var.cni_values

  depends_on = [helm_release.base]
}

resource "helm_release" "istiod" {
  count            = var.enabled ? 1 : 0
  name             = "istiod"
  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "istiod"
  version          = var.istiod_chart_version
  namespace        = var.namespace
  create_namespace = true
  wait             = true
  timeout          = var.helm_timeout_seconds
  values = concat(var.istiod_values, [yamlencode({
    pilot = {
      cni = {
        enabled = true
      }
    }
  })])

  depends_on = [helm_release.cni]
}

resource "kubernetes_labels" "application_namespace" {
  count       = var.enabled && var.enable_application_namespace_injection ? 1 : 0
  api_version = "v1"
  kind        = "Namespace"

  metadata {
    name = var.application_namespace
  }

  labels = {
    "istio-injection" = "enabled"
  }

  force = true

  depends_on = [helm_release.istiod]
}
