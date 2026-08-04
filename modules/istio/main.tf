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
  values           = var.istiod_values

  depends_on = [helm_release.base]
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
