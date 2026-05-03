# These are your "function parameters" — configurable values
# referenced throughout the other files as var.name
#
# You can override defaults via:
#   terraform apply -var="environment=prod"
#   or a terraform.tfvars file

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

variable "api_base_url" {
  description = "API Gateway URL from the pipeline stack (passed to dashboard as env var)"
  type        = string
  default     = ""
}
