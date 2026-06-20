variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "expire_days" {
  description = "Days before raw events are deleted from S3"
  type        = number
  default     = 365
}

variable "glacier_transition_days" {
  description = "Days before raw events transition to Glacier Instant Retrieval"
  type        = number
  default     = 30
}
