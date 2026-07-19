output "zone_id" { value = local.zone_id }
output "fqdn" { value = local.fqdn }
output "simple_record_fqdns" { value = { for record_type, record in aws_route53_record.simple : record_type => record.fqdn } }
output "primary_failover_record_fqdns" { value = { for record_type, record in aws_route53_record.primary_failover : record_type => record.fqdn } }
output "secondary_failover_record_fqdns" { value = { for record_type, record in aws_route53_record.secondary_failover : record_type => record.fqdn } }
output "primary_health_check_id" { value = var.enable_failover && var.create_health_checks ? aws_route53_health_check.primary[0].id : var.primary_health_check_id }
output "secondary_health_check_id" { value = var.enable_failover && var.create_health_checks && var.secondary_health_check_fqdn != null ? aws_route53_health_check.secondary[0].id : var.secondary_health_check_id }
