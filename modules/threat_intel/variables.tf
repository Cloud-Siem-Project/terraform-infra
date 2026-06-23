variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "lambda_src_dir" {
  description = "Path to enrichmentpipeline/src/ (contains ti_loader/ and flow_detector/ subdirs)"
  type        = string
}

variable "eb_bus_name" {
  description = "Custom EventBridge bus name — flow_detector publishes hits here"
  type        = string
}

variable "eb_bus_arn" {
  description = "Custom EventBridge bus ARN — used in IAM"
  type        = string
}

variable "vpc_flow_log_group_name" {
  description = "VPC Flow Logs CWL group name — flow_detector subscribes to it"
  type        = string
}

variable "vpc_flow_log_group_arn" {
  description = "VPC Flow Logs CWL group ARN — used for the lambda invoke permission"
  type        = string
}

variable "feed_url" {
  description = "Open-source IP blacklist feed. Default: abuse.ch Feodo Tracker (plain text, one IPv4/line, no auth)."
  type        = string
  default     = "https://feodotracker.abuse.ch/downloads/ipblocklist.txt"
}

variable "feed_source" {
  description = "Label stored on each feed-sourced row"
  type        = string
  default     = "abuse.ch/feodo"
}

variable "feed_ttl_days" {
  description = "Days a feed entry survives in DDB before TTL sweeps it (the schedule re-writes them well before this)"
  type        = number
  default     = 14
}

variable "seed_ips" {
  description = "Always-present demo entries (TEST-NET-1, unroutable) so the table is never empty and smoke tests have a safe target."
  type        = list(string)
  default     = ["192.0.2.66", "192.0.2.123"]
}

variable "refresh_schedule" {
  description = "EventBridge schedule expression for the loader refresh"
  type        = string
  default     = "rate(12 hours)"
}

variable "blacklist_cache_secs" {
  description = "How long flow_detector caches the blacklist in memory before re-scanning DDB"
  type        = number
  default     = 300
}

variable "lambda_runtime" {
  type    = string
  default = "python3.13"
}

variable "evidence_bucket_name" {
  description = "Evidence bucket name — if set, ti_loader saves the downloaded feed snapshot here"
  type        = string
  default     = ""
}

variable "evidence_bucket_arn" {
  description = "Evidence bucket ARN — gates the s3:PutObject grant"
  type        = string
  default     = ""
}
