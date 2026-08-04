resource "random_password" "origin_verification" {
  length  = 32
  special = false
}

locals {
  origin_verification_header_value = var.origin_verification_header_value != "" ? var.origin_verification_header_value : random_password.origin_verification.result
}

resource "aws_wafv2_web_acl" "this" {
  name  = "${var.name}-${var.environment}-edge"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedCommonRules"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-${var.environment}-common"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "FlashSaleRateLimit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit_per_5_min
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-${var.environment}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedIPReputationRules"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-${var.environment}-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}-${var.environment}-waf"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}

resource "aws_route53_record" "origin" {
  count   = var.manage_origin_dns ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.origin_domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = true
  aliases         = var.domain_name == "" ? [] : [var.domain_name]
  web_acl_id      = aws_wafv2_web_acl.this.arn

  origin {
    domain_name = var.origin_domain_name
    origin_id   = "alb"

    custom_header {
      name  = var.origin_verification_header_name
      value = local.origin_verification_header_value
    }

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "alb"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      # Do not forward the viewer Host header. CloudFront sends the custom
      # origin hostname so the ALB certificate and host rule continue to match.
      headers = ["Authorization", "Origin"]
      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn            = var.certificate_arn == "" ? null : var.certificate_arn
    cloudfront_default_certificate = var.certificate_arn == ""
    ssl_support_method             = var.certificate_arn == "" ? null : "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = var.tags
}
