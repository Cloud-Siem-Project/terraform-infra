variable "project_name" {
  description = "Project name, used for resource naming"
  type        = string
  default     = "cloudguard-dns"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "staging"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}
