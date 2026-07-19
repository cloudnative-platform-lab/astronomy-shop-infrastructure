resource "helm_release" "this" {
  count            = var.enabled ? 1 : 0
  name             = "argo-rollouts"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-rollouts"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  values           = var.values

  set {
    name  = "dashboard.enabled"
    value = tostring(var.enable_dashboard)
  }

  set {
    name  = "dashboard.service.type"
    value = var.dashboard_service_type
  }
}
