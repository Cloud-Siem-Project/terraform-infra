# Phase 1 outputs. Phase 2 reads these via terraform_remote_state to wire
# EventBridge rules + the raw archive.

output "cloudtrail_arn" {
  description = "CloudTrail ARN (null if disabled)"
  value       = try(module.cloudtrail[0].trail_arn, null)
}

output "cloudtrail_bucket" {
  description = "S3 bucket holding CloudTrail logs (null if disabled)"
  value       = try(module.cloudtrail[0].bucket_name, null)
}

output "vpc_flow_logs_group" {
  description = "VPC Flow Logs CWL group name (null if disabled)"
  value       = try(module.vpc_flow_logs[0].log_group_name, null)
}

output "route53_resolver_qlog_group" {
  description = "Route53 Resolver query log CWL group name (null if disabled)"
  value       = try(module.route53_resolver_qlog[0].log_group_name, null)
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID (null if disabled)"
  value       = try(module.guardduty[0].detector_id, null)
}

# ──────────────────────────────────────────────
# Phase 2 outputs — consumed by phase 3 pipeline lambdas.
# ──────────────────────────────────────────────

output "eb_bus_name" {
  description = "Custom EventBridge bus name (null if disabled)"
  value       = try(module.eventbridge_bus[0].bus_name, null)
}

output "eb_bus_arn" {
  description = "Custom EventBridge bus ARN (null if disabled)"
  value       = try(module.eventbridge_bus[0].bus_arn, null)
}

output "raw_archive_bucket" {
  description = "S3 bucket holding raw events (null if disabled)"
  value       = try(module.raw_archive[0].bucket_name, null)
}

output "firehose_eb_stream" {
  description = "Firehose delivery stream name (null if disabled)"
  value       = try(module.firehose_eb_to_s3[0].stream_name, null)
}

# ──────────────────────────────────────────────
# Phase 3 outputs
# ──────────────────────────────────────────────

output "events_table_name" {
  description = "DDB events table name (null if pipeline disabled)"
  value       = try(module.pipeline[0].events_table_name, null)
}

output "dns_detector_function" {
  description = "dns_detector lambda name (null if pipeline disabled)"
  value       = try(module.pipeline[0].dns_detector_function_name, null)
}

output "persist_function" {
  description = "persist lambda name (null if pipeline disabled)"
  value       = try(module.pipeline[0].persist_function_name, null)
}

output "pipeline_state_machine_arn" {
  description = "Step Functions state machine ARN (null if pipeline disabled)"
  value       = try(module.pipeline[0].state_machine_arn, null)
}

# ──────────────────────────────────────────────
# Phase 4 outputs
# ──────────────────────────────────────────────

output "alerts_topic_arn" {
  description = "SNS alerts topic ARN (null if outputs disabled)"
  value       = try(module.outputs[0].sns_topic_arn, null)
}

output "blocklist_ipset_id" {
  description = "WAFv2 IPSet id (null if outputs disabled)"
  value       = try(module.outputs[0].ipset_id, null)
}

output "block_ip_function" {
  description = "block_ip lambda name (null if outputs disabled)"
  value       = try(module.outputs[0].block_ip_function_name, null)
}

output "email_subscription_pending" {
  description = "True if alert_email is set; user needs to confirm via email"
  value       = try(module.outputs[0].email_subscription_pending, false)
}

# ──────────────────────────────────────────────
# Phase 5 outputs — dashboard stack reads these via terraform_remote_state
# ──────────────────────────────────────────────

output "events_api_domain" {
  description = "API Gateway host portion — use as CloudFront origin domain (null if disabled)"
  value       = try(module.dashboard_api[0].api_domain, null)
}

output "events_api_endpoint" {
  description = "Full execute-api URL (null if disabled)"
  value       = try(module.dashboard_api[0].api_endpoint, null)
}

output "dashboard_api_function" {
  description = "dashboard_api lambda name (null if disabled)"
  value       = try(module.dashboard_api[0].lambda_function_name, null)
}
