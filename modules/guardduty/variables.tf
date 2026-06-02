variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "finding_publishing_frequency" {
  description = "FIFTEEN_MINUTES | ONE_HOUR | SIX_HOURS"
  type        = string
  default     = "FIFTEEN_MINUTES"
}

variable "enable_s3_protection" {
  description = "Enable GuardDuty S3 Protection (data plane events)"
  type        = bool
  default     = true
}
