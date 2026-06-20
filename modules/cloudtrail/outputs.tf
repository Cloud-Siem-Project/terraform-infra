output "trail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.main.arn
}

output "trail_name" {
  description = "Name of the CloudTrail trail"
  value       = aws_cloudtrail.main.name
}

output "bucket_name" {
  description = "S3 bucket holding CloudTrail logs"
  value       = aws_s3_bucket.trail.id
}

output "bucket_arn" {
  description = "ARN of the CloudTrail log bucket"
  value       = aws_s3_bucket.trail.arn
}
