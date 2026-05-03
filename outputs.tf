# These are your "return values" — printed after terraform apply
# and queryable anytime with: terraform output bucket_name
#
# You'll copy these into your dashboard repo's CI/CD secrets

output "bucket_name" {
  description = "S3 bucket name — used in CI/CD: aws s3 sync dist/ s3://THIS_VALUE"
  value       = aws_s3_bucket.dashboard.id
}

output "distribution_id" {
  description = "CloudFront distribution ID — used in CI/CD for cache invalidation"
  value       = aws_cloudfront_distribution.dashboard.id
}

output "dashboard_url" {
  description = "Live dashboard URL — share this with your team and advisor"
  value       = "https://${aws_cloudfront_distribution.dashboard.domain_name}"
}
