output "alerts_topic_arn" { value = aws_sns_topic.alerts.arn }
output "metrics_server_release_name" { value = try(helm_release.metrics_server[0].name, null) }
output "prometheus_release_name" { value = try(helm_release.kube_prometheus_stack[0].name, null) }
output "loki_release_name" { value = try(helm_release.loki[0].name, null) }
output "tempo_release_name" { value = try(helm_release.tempo[0].name, null) }
output "opentelemetry_collector_release_name" { value = try(helm_release.opentelemetry_collector[0].name, null) }
