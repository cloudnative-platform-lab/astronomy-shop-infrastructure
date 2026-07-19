locals {
  create_certificate      = var.domain_name != ""
  create_records          = local.create_certificate && var.create_validation_records && var.route53_zone_id != null
  validation_record_fqdns = local.create_records ? [for record in aws_route53_record.validation : record.fqdn] : var.validation_record_fqdns
}

resource "aws_acm_certificate" "this" {
  count = local.create_certificate ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"
  tags                      = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = local.create_records ? {
    for option in aws_acm_certificate.this[0].domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

resource "aws_acm_certificate_validation" "this" {
  count = local.create_certificate && length(local.validation_record_fqdns) > 0 ? 1 : 0

  certificate_arn         = aws_acm_certificate.this[0].arn
  validation_record_fqdns = local.validation_record_fqdns
}
