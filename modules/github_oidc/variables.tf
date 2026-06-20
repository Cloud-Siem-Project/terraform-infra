variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "github_repos" {
  description = "GitHub repos allowed to assume this role (org/repo format)"
  type        = list(string)
}

variable "s3_bucket_arns" {
  description = "S3 bucket ARNs the deploy role can write to"
  type        = list(string)
}

variable "cloudfront_arns" {
  description = "CloudFront distribution ARNs the deploy role can invalidate"
  type        = list(string)
}

variable "lambda_arns" {
  description = "Lambda function ARNs the deploy role can update"
  type        = list(string)
  default     = []
}
