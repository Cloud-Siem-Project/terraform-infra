variable "project_name" {
  description = "Project name, used for resource naming"
  type        = string
  default     = "cloudguard-dns"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1"
}

variable "custom_domain" {
  description = "Custom domain for the dashboard (e.g. cloudlogger.com). Empty = use CloudFront default domain."
  type        = string
  default     = ""
}
