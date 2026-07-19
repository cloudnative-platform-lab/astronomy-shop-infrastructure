locals {
  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : var.zone_id
  fqdn    = var.record_name == "" ? var.zone_name : "${var.record_name}.${var.zone_name}"

  primary_records = {
    for record_type in var.record_types : record_type => {
      name    = local.fqdn
      type    = record_type
      zone_id = local.zone_id
    }
  }
}

resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0
  name  = var.zone_name
  tags  = var.tags
}

resource "aws_route53_health_check" "primary" {
  count             = var.enable_failover && var.create_health_checks ? 1 : 0
  fqdn              = var.primary_health_check_fqdn
  port              = var.health_check_port
  type              = var.health_check_protocol
  resource_path     = var.health_check_path
  failure_threshold = var.health_check_failure_threshold
  request_interval  = var.health_check_request_interval
  tags              = merge(var.tags, { Name = "${var.name}-${var.environment}-primary" })
}

resource "aws_route53_health_check" "secondary" {
  count             = var.enable_failover && var.create_health_checks && var.secondary_health_check_fqdn != null ? 1 : 0
  fqdn              = var.secondary_health_check_fqdn
  port              = var.health_check_port
  type              = var.health_check_protocol
  resource_path     = var.health_check_path
  failure_threshold = var.health_check_failure_threshold
  request_interval  = var.health_check_request_interval
  tags              = merge(var.tags, { Name = "${var.name}-${var.environment}-secondary" })
}

resource "aws_route53_record" "simple" {
  for_each = var.enable_failover ? {} : local.primary_records

  zone_id = each.value.zone_id
  name    = each.value.name
  type    = each.value.type

  alias {
    name                   = var.primary_alias_domain_name
    zone_id                = var.primary_alias_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

resource "aws_route53_record" "primary_failover" {
  for_each = var.enable_failover ? local.primary_records : {}

  zone_id         = each.value.zone_id
  name            = each.value.name
  type            = each.value.type
  set_identifier  = "primary"
  health_check_id = var.primary_health_check_id != null ? var.primary_health_check_id : (var.create_health_checks ? aws_route53_health_check.primary[0].id : null)

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = var.primary_alias_domain_name
    zone_id                = var.primary_alias_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

resource "aws_route53_record" "secondary_failover" {
  for_each = var.enable_failover ? local.primary_records : {}

  zone_id         = each.value.zone_id
  name            = each.value.name
  type            = each.value.type
  set_identifier  = "secondary"
  health_check_id = var.secondary_health_check_id != null ? var.secondary_health_check_id : (var.create_health_checks && var.secondary_health_check_fqdn != null ? aws_route53_health_check.secondary[0].id : null)

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = var.secondary_alias_domain_name
    zone_id                = var.secondary_alias_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}
