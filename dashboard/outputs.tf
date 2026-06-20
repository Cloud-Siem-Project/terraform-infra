output "bucket_name" {
  description = "S3 bucket name — used in CI/CD: aws s3 sync dist/ s3://THIS_VALUE"
  value       = module.dashboard_hosting.bucket_name
}

output "distribution_id" {
  description = "CloudFront distribution ID — used in CI/CD for cache invalidation"
  value       = module.dashboard_hosting.distribution_id
}

output "dashboard_url" {
  description = "Live dashboard URL"
  value       = module.dashboard_hosting.dashboard_url
}

output "github_actions_role_arn" {
  description = "IAM role ARN — set as AWS_ROLE_ARN secret in each GitHub repo"
  value       = module.github_oidc.role_arn
}

output "acm_validation_records" {
  description = "Add these DNS records in Cloudflare to validate the ACM certificate"
  value       = module.dashboard_hosting.acm_validation_records
}
