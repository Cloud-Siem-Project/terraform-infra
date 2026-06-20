output "bucket_name" {
  description = "Raw event archive bucket name"
  value       = aws_s3_bucket.raw.id
}

output "bucket_arn" {
  description = "Raw event archive bucket ARN"
  value       = aws_s3_bucket.raw.arn
}
