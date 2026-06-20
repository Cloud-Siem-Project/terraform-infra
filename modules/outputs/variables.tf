variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "alert_email" {
  description = "Email address subscribed to the alerts SNS topic. Empty = no subscription."
  type        = string
  default     = ""
}

variable "lambda_src_dir" {
  description = "Path to enrichmentpipeline/src/ (block_ip subdir lives here)"
  type        = string
}

variable "lambda_runtime" {
  type    = string
  default = "python3.13"
}

variable "ipset_scope" {
  description = "WAFv2 IPSet scope. REGIONAL for ALB/API GW. CLOUDFRONT requires us-east-1 provider — out of scope for now."
  type        = string
  default     = "REGIONAL"
}
