output "certificate_arn" {
  value = try(aws_acm_certificate_validation.this[0].certificate_arn, aws_acm_certificate.this[0].arn, null)
}

output "validation_record_fqdns" {
  value = [for record in aws_route53_record.validation : record.fqdn]
}
