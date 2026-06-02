variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "events_table_name" {
  type = string
}

variable "events_table_arn" {
  type = string
}

variable "lambda_src_dir" {
  description = "Path to enrichmentpipeline/src/ (dashboard_api subdir lives here)"
  type        = string
}

variable "lambda_runtime" {
  type    = string
  default = "python3.13"
}

variable "lambda_memory_mb" {
  type    = number
  default = 256
}

variable "lambda_timeout" {
  type    = number
  default = 10
}

# ──────────────────────────────────────────────
# Optional pipeline status inputs — when set, the λ exposes GET /api/pipeline
# returning SFN executions + WAF blocklist + CW metrics + event counts.
# ──────────────────────────────────────────────

variable "sfn_arn" {
  description = "Step Functions state machine ARN — empty disables sfn lookups in /api/pipeline"
  type        = string
  default     = ""
}

variable "ipset_name" {
  description = "WAFv2 IPSet name"
  type        = string
  default     = ""
}

variable "ipset_id" {
  description = "WAFv2 IPSet id"
  type        = string
  default     = ""
}

variable "ipset_arn" {
  description = "WAFv2 IPSet arn — used to scope IAM"
  type        = string
  default     = ""
}

variable "ipset_scope" {
  type    = string
  default = "REGIONAL"
}

variable "sns_topic_name" {
  description = "SNS topic name for the alerts metric"
  type        = string
  default     = ""
}

variable "eb_bus_name" {
  description = "Custom EventBridge bus name (for MatchedEvents metric)"
  type        = string
  default     = ""
}

variable "eb_catchall_rule_name" {
  description = "EventBridge catch-all rule name on the custom bus"
  type        = string
  default     = ""
}

variable "lambda_names_for_metrics" {
  description = "Lambda function names to report Invocations for in /api/pipeline"
  type        = list(string)
  default     = []
}
