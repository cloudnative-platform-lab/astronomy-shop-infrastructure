output "application_log_group_name" { value = local.application_log_group_name }
output "dashboard_name" { value = aws_cloudwatch_dashboard.platform.dashboard_name }
output "application_error_alarm_arn" { value = aws_cloudwatch_metric_alarm.application_errors.arn }
