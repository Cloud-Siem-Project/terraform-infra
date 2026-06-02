variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "log_retention_days" {
  description = "How long to keep CloudTrail logs in S3 before expiry"
  type        = number
  default     = 90
}

variable "glacier_transition_days" {
  description = "Days before transitioning logs to Glacier"
  type        = number
  default     = 30
}
