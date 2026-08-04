output "cloudfront_domain_name" { value = aws_cloudfront_distribution.this.domain_name }
output "cloudfront_distribution_id" { value = aws_cloudfront_distribution.this.id }
output "cloudfront_hosted_zone_id" { value = aws_cloudfront_distribution.this.hosted_zone_id }
output "waf_acl_arn" { value = aws_wafv2_web_acl.this.arn }
output "origin_verification_header_name" { value = var.origin_verification_header_name }
output "origin_verification_header_value" {
  value     = local.origin_verification_header_value
  sensitive = true
}
