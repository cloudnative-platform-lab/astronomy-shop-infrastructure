output "budget_name" { value = aws_budgets_budget.monthly.name }
output "kubecost_enabled" { value = var.enable_kubecost }
output "kubecost_namespace" { value = var.enable_kubecost ? var.kubecost_namespace : null }
output "kubecost_release_name" { value = try(helm_release.kubecost[0].name, null) }
