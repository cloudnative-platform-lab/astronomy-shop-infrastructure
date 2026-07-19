resource "aws_budgets_budget" "monthly" {
  name         = "${var.name}-${var.environment}-monthly-budget"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  dynamic "notification" {
    for_each = var.alert_email == "" ? [] : [var.alert_email]

    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = 80
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = [notification.value]
    }
  }
}

resource "helm_release" "kubecost" {
  count = var.enable_kubecost ? 1 : 0

  name             = "kubecost"
  repository       = "https://kubecost.github.io/cost-analyzer/"
  chart            = "cost-analyzer"
  version          = var.kubecost_chart_version
  namespace        = var.kubecost_namespace
  create_namespace = true
  wait             = true
  timeout          = var.kubecost_helm_timeout
  values           = var.kubecost_values

  set {
    name  = "kubecostProductConfigs.clusterName"
    value = "${var.name}-${var.environment}"
  }
}
