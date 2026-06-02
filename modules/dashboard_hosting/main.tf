# Dashboard hosting: private S3 bucket + CloudFront distribution with OAC.
# Frontend repo (CSP/frontend) builds and syncs to the bucket; CloudFront
# serves the SPA over HTTPS and rewrites 403/404 to /index.html for client-side routing.

locals {
  has_custom_domain = var.custom_domain != ""
}

resource "aws_acm_certificate" "dashboard" {
  count             = local.has_custom_domain ? 1 : 0
  provider          = aws.us_east_1
  domain_name       = var.custom_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "dashboard" {
  bucket = "${var.project_name}-${var.environment}-dashboard"
}

resource "aws_s3_bucket_public_access_block" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "dashboard" {
  name                              = "${var.project_name}-${var.environment}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

locals {
  api_enabled        = var.api_origin_domain != ""
  events_api_enabled = var.events_api_origin_domain != ""
}

resource "aws_cloudfront_distribution" "dashboard" {
  enabled             = true
  default_root_object = "index.html"
  comment             = "${var.project_name} dashboard (${var.environment})"
  aliases             = local.has_custom_domain ? [var.custom_domain] : []

  origin {
    domain_name              = aws_s3_bucket.dashboard.bucket_regional_domain_name
    origin_id                = "s3-dashboard"
    origin_access_control_id = aws_cloudfront_origin_access_control.dashboard.id
  }

  # Backend API origin — only present when api_origin_domain is set.
  # Custom HTTP origin (the EC2 SG allows ingress from CloudFront's prefix list).
  dynamic "origin" {
    for_each = local.api_enabled ? [1] : []
    content {
      domain_name = var.api_origin_domain
      origin_id   = "ec2-backend-api"

      custom_origin_config {
        http_port              = var.api_origin_port
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # Events API origin — API Gateway v2 HTTP API for /api/events*
  # HTTPS-only (API GW doesn't serve HTTP).
  dynamic "origin" {
    for_each = local.events_api_enabled ? [1] : []
    content {
      domain_name = var.events_api_origin_domain
      origin_id   = "events-api"

      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-dashboard"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # AWS managed CachingOptimized policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # /api/events* → API Gateway. Declared BEFORE /api/* so CloudFront's
  # path-pattern precedence (order-based, more-specific must be first) picks
  # this over the EC2 backend route.
  dynamic "ordered_cache_behavior" {
    for_each = local.events_api_enabled ? [1] : []
    content {
      path_pattern           = "/api/events*"
      target_origin_id       = "events-api"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      compress               = true

      # Managed-CachingDisabled
      cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
      # Managed-AllViewerExceptHostHeader
      origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
    }
  }

  # /api/pipeline* → same API Gateway origin as /api/events*. Both routes
  # are served by the dashboard_api lambda. Declared before /api/* so it
  # doesn't fall through to the EC2 backend.
  dynamic "ordered_cache_behavior" {
    for_each = local.events_api_enabled ? [1] : []
    content {
      path_pattern           = "/api/pipeline*"
      target_origin_id       = "events-api"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      compress               = true

      cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
      origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
    }
  }

  # Forward /api/* to the backend with no caching, full method set,
  # and all viewer headers/cookies/query-strings (except Host).
  dynamic "ordered_cache_behavior" {
    for_each = local.api_enabled ? [1] : []
    content {
      path_pattern           = "/api/*"
      target_origin_id       = "ec2-backend-api"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
      cached_methods         = ["GET", "HEAD"]
      compress               = true

      # Managed-CachingDisabled
      cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
      # Managed-AllViewerExceptHostHeader
      origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
    }
  }

  # SPA routing: S3 returns 403/404 for non-existent paths like /events.
  # Rewrite to /index.html so the frontend router can handle the path.
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "viewer_certificate" {
    for_each = local.has_custom_domain ? [1] : []
    content {
      acm_certificate_arn      = aws_acm_certificate.dashboard[0].arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  dynamic "viewer_certificate" {
    for_each = local.has_custom_domain ? [] : [1]
    content {
      cloudfront_default_certificate = true
    }
  }
}

resource "aws_s3_bucket_policy" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOAC"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.dashboard.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.dashboard.arn
          }
        }
      }
    ]
  })
}
