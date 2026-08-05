resource "aws_sns_topic" "alerts" {
  name = "${var.name}-${var.environment}-platform-alerts"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

locals {
  enable_alertmanager_sns           = var.enable_alertmanager && var.enable_alertmanager_sns && var.alert_email != "" && var.cluster_name != ""
  alertmanager_service_account_name = "alertmanager-sns"
}

data "aws_iam_policy_document" "alertmanager_assume_role" {
  count = local.enable_alertmanager_sns ? 1 : 0

  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "alertmanager_sns" {
  count = local.enable_alertmanager_sns ? 1 : 0

  statement {
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts.arn]
  }
}

resource "aws_iam_role" "alertmanager" {
  count = local.enable_alertmanager_sns ? 1 : 0

  name               = "${var.name}-${var.environment}-alertmanager"
  assume_role_policy = data.aws_iam_policy_document.alertmanager_assume_role[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy" "alertmanager_sns" {
  count = local.enable_alertmanager_sns ? 1 : 0

  name   = "sns-publish"
  role   = aws_iam_role.alertmanager[0].id
  policy = data.aws_iam_policy_document.alertmanager_sns[0].json
}

resource "kubernetes_service_account_v1" "alertmanager" {
  count = local.enable_alertmanager_sns ? 1 : 0

  metadata {
    name      = local.alertmanager_service_account_name
    namespace = "observability"
  }
}

resource "aws_eks_pod_identity_association" "alertmanager" {
  count = local.enable_alertmanager_sns ? 1 : 0

  cluster_name    = var.cluster_name
  namespace       = kubernetes_service_account_v1.alertmanager[0].metadata[0].namespace
  service_account = kubernetes_service_account_v1.alertmanager[0].metadata[0].name
  role_arn        = aws_iam_role.alertmanager[0].arn

  depends_on = [aws_iam_role_policy.alertmanager_sns]
}

resource "kubernetes_storage_class_v1" "gp3" {
  count = var.enable_persistence ? 1 : 0

  metadata {
    name = "gp3"
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Retain"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}

resource "helm_release" "metrics_server" {
  count = var.enable_metrics_server ? 1 : 0

  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  version          = var.metrics_server_chart_version
  namespace        = "kube-system"
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [
    yamlencode({
      args = [
        "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
        "--kubelet-use-node-status-port"
      ]
      resources = {
        requests = {
          cpu    = "100m"
          memory = "200Mi"
        }
      }
    })
  ]
}

resource "helm_release" "kube_prometheus_stack" {
  count            = var.enable_monitoring_stack && var.enable_kube_prometheus_stack ? 1 : 0
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.kube_prometheus_stack_chart_version
  namespace        = "observability"
  create_namespace = true
  wait             = false
  timeout          = 900

  values = concat([
    yamlencode({
      alertmanager = {
        enabled = var.enable_alertmanager
      }
      prometheus = {
        prometheusSpec = {
          retention                               = var.prometheus_retention
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
          storageSpec = var.enable_persistence ? {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "20Gi"
                  }
                }
              }
            }
          } : null
        }
      }
      grafana = {
        persistence = {
          enabled          = var.enable_persistence
          storageClassName = var.enable_persistence ? "gp3" : null
          size             = "10Gi"
        }
      }
    })
    ], local.enable_alertmanager_sns ? [
    yamlencode({
      alertmanager = {
        alertmanagerSpec = {
          serviceAccountName = local.alertmanager_service_account_name
        }
        config = {
          global = {
            resolve_timeout = "5m"
          }
          route = {
            receiver        = "platform-sns"
            group_by        = ["alertname", "namespace"]
            group_wait      = "30s"
            group_interval  = "5m"
            repeat_interval = "4h"
          }
          receivers = [{
            name = "platform-sns"
            sns_configs = [{
              topic_arn = aws_sns_topic.alerts.arn
              subject   = "[${var.environment}] Astronomy Shop alert"
              sigv4 = {
                region = var.aws_region
              }
            }]
          }]
        }
      }
    })
  ] : [])

  depends_on = [
    kubernetes_storage_class_v1.gp3,
    aws_eks_pod_identity_association.alertmanager
  ]
}

resource "helm_release" "loki" {
  count            = var.enable_monitoring_stack && var.enable_loki ? 1 : 0
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  version          = var.loki_stack_chart_version
  namespace        = "observability"
  create_namespace = true
  wait             = true
  timeout          = 900

  values = [
    yamlencode({
      loki = {
        isDefault = false
        persistence = {
          enabled          = var.enable_persistence
          storageClassName = var.enable_persistence ? "gp3" : null
          size             = "20Gi"
        }
      }
      promtail = {
        enabled = true
      }
      grafana = {
        enabled = false
      }
      prometheus = {
        enabled = false
      }
    })
  ]

  depends_on = [kubernetes_storage_class_v1.gp3]
}

resource "helm_release" "tempo" {
  count = var.enable_monitoring_stack && var.enable_tempo ? 1 : 0

  name             = "tempo"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "tempo"
  version          = var.tempo_chart_version
  namespace        = "observability"
  create_namespace = true
  wait             = true
  timeout          = 900

  values = [
    yamlencode({
      persistence = {
        enabled          = var.enable_persistence
        storageClassName = var.enable_persistence ? "gp3" : null
        size             = "20Gi"
      }
      tempo = {
        receivers = {
          otlp = {
            protocols = {
              grpc = {}
              http = {}
            }
          }
        }
      }
    })
  ]

  depends_on = [kubernetes_storage_class_v1.gp3]
}

resource "helm_release" "opentelemetry_collector" {
  count            = var.enable_monitoring_stack && var.enable_opentelemetry_collector ? 1 : 0
  name             = "opentelemetry-collector"
  repository       = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart            = "opentelemetry-collector"
  version          = var.opentelemetry_collector_chart_version
  namespace        = "observability"
  create_namespace = true
  wait             = true
  timeout          = 900

  values = [
    yamlencode({
      mode = "deployment"
      image = {
        repository = "otel/opentelemetry-collector-k8s"
      }
      config = {
        receivers = {
          otlp = {
            protocols = {
              grpc = {}
              http = {}
            }
          }
        }
        processors = {
          batch = {}
          memory_limiter = {
            check_interval = "5s"
            limit_mib      = 400
          }
        }
        exporters = merge(
          { debug = {} },
          var.enable_tempo ? {
            otlp = {
              endpoint = "tempo.observability.svc.cluster.local:4317"
              tls = {
                insecure = true
              }
            }
          } : {}
        )
        service = {
          pipelines = {
            traces = {
              receivers  = ["otlp"]
              processors = ["memory_limiter", "batch"]
              exporters  = var.enable_tempo ? ["otlp", "debug"] : ["debug"]
            }
            metrics = {
              receivers  = ["otlp"]
              processors = ["memory_limiter", "batch"]
              exporters  = ["debug"]
            }
            logs = {
              receivers  = ["otlp"]
              processors = ["memory_limiter", "batch"]
              exporters  = ["debug"]
            }
          }
        }
      }
    })
  ]

  depends_on = [helm_release.tempo]
}
