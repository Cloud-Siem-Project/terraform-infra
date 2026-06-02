variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "stream_name_suffix" {
  description = "Trailing identifier for the firehose stream — e.g. \"eb\" for EventBridge"
  type        = string
  default     = "events"
}

variable "destination_bucket_arn" {
  description = "S3 bucket ARN where Firehose writes batches"
  type        = string
}

variable "destination_prefix" {
  description = "S3 key prefix — keep trailing slash. e.g. \"eb/\""
  type        = string
  default     = "eb/"
}

variable "buffering_interval" {
  description = "Seconds Firehose waits before flushing a buffer. Min 60."
  type        = number
  default     = 60
}

variable "buffering_size_mb" {
  description = "MB threshold Firehose flushes at"
  type        = number
  default     = 5
}

variable "log_retention_days" {
  description = "Retention on the Firehose error CWL group"
  type        = number
  default     = 14
}
