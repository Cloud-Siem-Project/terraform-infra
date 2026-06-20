variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "eb_bus_name" {
  description = "Custom EventBridge bus name — pipeline rule lives on this bus"
  type        = string
}

variable "eb_bus_arn" {
  description = "Custom EventBridge bus ARN — used in IAM"
  type        = string
}

variable "raw_archive_bucket" {
  description = "Raw event archive bucket name (S3) — persist lambda writes here"
  type        = string
}

variable "raw_archive_bucket_arn" {
  description = "Raw event archive bucket ARN — used in IAM"
  type        = string
}

variable "r53_resolver_log_group_name" {
  description = "Route53 resolver query log CWL group name — dns_detector subscribes to it"
  type        = string
}

variable "r53_resolver_log_group_arn" {
  description = "Route53 resolver query log CWL group ARN — used in IAM"
  type        = string
}

variable "lambda_src_dir" {
  description = "Path to enrichmentpipeline/src/ (contains dns_detector/ and persist/ subdirs)"
  type        = string
}

variable "statemachine_asl_path" {
  description = "Path to the Step Functions ASL JSON template"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda runtime. python3.13 has PEP 604 native + boto3 baked in."
  type        = string
  default     = "python3.13"
}

variable "lambda_timeout" {
  type    = number
  default = 30
}

variable "lambda_memory_mb" {
  type    = number
  default = 256
}

variable "events_ttl_days" {
  description = "Days an event stays in DDB before TTL sweeps it"
  type        = number
  default     = 30
}

variable "sns_topic_arn" {
  description = "Alerts SNS topic ARN — SFN HighSeverityHook publishes here"
  type        = string
}

variable "block_ip_function_arn" {
  description = "block_ip lambda ARN — SFN HighSeverityHook invokes this in parallel with SNS"
  type        = string
}
