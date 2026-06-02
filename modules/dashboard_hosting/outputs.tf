output "bucket_name" {
  description = "S3 bucket name for the dashboard build artifacts"
  value       = aws_s3_bucket.dashboard.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.dashboard.arn
}

output "distribution_id" {
  description = "CloudFront distribution ID — used in CI/CD for cache invalidation"
  value       = aws_cloudfront_distribution.dashboard.id
}

output "dashboard_url" {
  description = "Live dashboard URL"
  value       = local.has_custom_domain ? "https://${var.custom_domain}" : "https://${aws_cloudfront_distribution.dashboard.domain_name}"
}

output "acm_validation_records" {
  description = "DNS records to add in Cloudflare for ACM certificate validation"
  value = local.has_custom_domain ? [
    for dvo in aws_acm_certificate.dashboard[0].domain_validation_options : {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  ] : []
}
