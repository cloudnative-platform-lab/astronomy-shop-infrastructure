locals {
  application_log_group_name = var.application_log_group_name != "" ? var.application_log_group_name : "/aws/containerinsights/${var.cluster_name}/application"
}

resource "aws_cloudwatch_log_metric_filter" "application_errors" {
  name           = "${var.name}-${var.environment}-application-errors"
  pattern        = "?ERROR ?Error ?error ?Exception"
  log_group_name = local.application_log_group_name

  metric_transformation {
    name      = "ApplicationErrorCount"
    namespace = "${var.name}/${var.environment}"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "application_errors" {
  alarm_name          = "${var.name}-${var.environment}-application-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ApplicationErrorCount"
  namespace           = "${var.name}/${var.environment}"
  period              = 300
  statistic           = "Sum"
  threshold           = var.application_error_threshold
  alarm_actions       = [var.alert_topic_arn]
  ok_actions          = [var.alert_topic_arn]
  treat_missing_data  = "notBreaching"
  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cluster_utilization" {
  for_each = {
    cpu = {
      metric    = "node_cpu_utilization"
      threshold = var.node_cpu_threshold
    }
    memory = {
      metric    = "node_memory_utilization"
      threshold = var.node_memory_threshold
    }
  }

  alarm_name          = "${var.name}-${var.environment}-node-${each.key}-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = each.value.metric
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = each.value.threshold
  alarm_actions       = [var.alert_topic_arn]
  ok_actions          = [var.alert_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cluster_failed_nodes" {
  alarm_name          = "${var.name}-${var.environment}-eks-failed-nodes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "cluster_failed_node_count"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  alarm_actions       = [var.alert_topic_arn]
  ok_actions          = [var.alert_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_dashboard" "platform" {
  dashboard_name = "${var.name}-${var.environment}-platform"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "EKS Node Health"
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          metrics = [
            ["ContainerInsights", "cluster_failed_node_count", "ClusterName", var.cluster_name],
            [".", "node_cpu_utilization", ".", "."],
            [".", "node_memory_utilization", ".", "."]
          ]
        }
      }
    ]
  })
}

data "aws_region" "current" {}
