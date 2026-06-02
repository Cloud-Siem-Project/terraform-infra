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
  description = "AWS region for all SIEM resources"
  type        = string
  default     = "eu-central-1"
}

variable "alert_email" {
  description = "Email address subscribed to the SNS alert topic. Set via tfvars."
  type        = string
  default     = ""
}

# ──────────────────────────────────────────────
# Phase 1 — Data source toggles. Default on; flip to false if costs spike.
# ──────────────────────────────────────────────

variable "enable_cloudtrail" {
  type    = bool
  default = true
}

variable "enable_vpc_flow_logs" {
  type    = bool
  default = true
}

variable "enable_route53_resolver_qlog" {
  type    = bool
  default = true
}

variable "enable_guardduty" {
  description = "Off by default — this AWS account returned SubscriptionRequiredException on CreateDetector (sandbox/educator account type). Flip to true once GuardDuty is enabled on the account."
  type        = bool
  default     = false
}

# ──────────────────────────────────────────────
# Phase 2 — Ingestion toggle. Builds the EB bus + S3 archive + Firehose path.
# ──────────────────────────────────────────────

variable "enable_ingestion" {
  type    = bool
  default = true
}

variable "enable_firehose_archive" {
  description = "Off by default — this account returned SubscriptionRequiredException on CreateDeliveryStream. EB native archive still works. Phase 3 lambdas will write raw events to S3 directly."
  type        = bool
  default     = false
}

# ──────────────────────────────────────────────
# Phase 3 — Pipeline (DDB + lambdas + Step Functions)
# ──────────────────────────────────────────────

variable "enable_pipeline" {
  type    = bool
  default = true
}

# ──────────────────────────────────────────────
# Phase 4 — Outputs (SNS alerts + WAFv2 IPSet)
# ──────────────────────────────────────────────

variable "enable_outputs" {
  type    = bool
  default = true
}

# ──────────────────────────────────────────────
# Phase 5 — Dashboard API (HTTP API + Lambda → DDB)
# ──────────────────────────────────────────────

variable "enable_dashboard_api" {
  type    = bool
  default = true
}
