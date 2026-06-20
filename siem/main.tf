# SIEM root stack.
#
# Phase 1 wires the four data sources. Each is gated by an enable_* flag so
# any one can be flipped off without unwinding the whole stack.
#
# Phase 2+ will compose:
#   module "ingestion"      — EventBridge bus + rules + raw S3 archive
#   module "pipeline"       — Lambdas (enrichmentpipeline/src/), Step Functions, DynamoDB
#   module "outputs"        — SNS topic, WAFv2 IPSet
#   module "dashboard_api"  — API Gateway + Lambda → DynamoDB

# Default VPC — flow logs + resolver query logs attach here.
data "aws_vpc" "default" {
  default = true
}

module "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  source = "../modules/cloudtrail"

  project_name = var.project_name
  environment  = var.environment
}

module "vpc_flow_logs" {
  count  = var.enable_vpc_flow_logs ? 1 : 0
  source = "../modules/vpc_flow_logs"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = data.aws_vpc.default.id
}

module "route53_resolver_qlog" {
  count  = var.enable_route53_resolver_qlog ? 1 : 0
  source = "../modules/route53_resolver_qlog"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = data.aws_vpc.default.id
}

module "guardduty" {
  count  = var.enable_guardduty ? 1 : 0
  source = "../modules/guardduty"

  project_name = var.project_name
  environment  = var.environment
}

# ──────────────────────────────────────────────
# Phase 2 — Ingestion: EB custom bus → Firehose → S3 raw archive.
# Default bus events (aws.guardduty, aws.signin) are forwarded into our bus.
# ──────────────────────────────────────────────

module "raw_archive" {
  count  = var.enable_ingestion ? 1 : 0
  source = "../modules/raw_archive"

  project_name = var.project_name
  environment  = var.environment
}

module "eventbridge_bus" {
  count  = var.enable_ingestion ? 1 : 0
  source = "../modules/eventbridge_bus"

  project_name = var.project_name
  environment  = var.environment
}

module "firehose_eb_to_s3" {
  count  = var.enable_ingestion && var.enable_firehose_archive ? 1 : 0
  source = "../modules/firehose_to_s3"

  project_name           = var.project_name
  environment            = var.environment
  stream_name_suffix     = "eb-events"
  destination_bucket_arn = module.raw_archive[0].bucket_arn
  destination_prefix     = "eb/"
}

# ──────────────────────────────────────────────
# IAM — one role EventBridge assumes for both targets:
#   1. PutRecord(Batch) on the Firehose stream (catch-all rule)
#   2. PutEvents on the custom bus (forwarding rules on default bus)
# ──────────────────────────────────────────────

data "aws_iam_policy_document" "eb_assume" {
  count = var.enable_ingestion ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eb_targets" {
  count              = var.enable_ingestion ? 1 : 0
  name               = "${var.project_name}-${var.environment}-eb-targets"
  assume_role_policy = data.aws_iam_policy_document.eb_assume[0].json
}

data "aws_iam_policy_document" "eb_targets" {
  count = var.enable_ingestion ? 1 : 0

  dynamic "statement" {
    for_each = var.enable_firehose_archive ? [1] : []
    content {
      sid    = "FirehosePut"
      effect = "Allow"
      actions = [
        "firehose:PutRecord",
        "firehose:PutRecordBatch",
      ]
      resources = [module.firehose_eb_to_s3[0].stream_arn]
    }
  }

  statement {
    sid       = "BusPutEvents"
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = [module.eventbridge_bus[0].bus_arn]
  }
}

resource "aws_iam_role_policy" "eb_targets" {
  count  = var.enable_ingestion ? 1 : 0
  name   = "${var.project_name}-${var.environment}-eb-targets"
  role   = aws_iam_role.eb_targets[0].id
  policy = data.aws_iam_policy_document.eb_targets[0].json
}

# ──────────────────────────────────────────────
# Catch-all rule on our custom bus → Firehose
# Anything that lands on cloudguard-dns-events gets archived to S3.
# ──────────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "catch_all" {
  count          = var.enable_ingestion && var.enable_firehose_archive ? 1 : 0
  name           = "${var.project_name}-${var.environment}-catch-all"
  description    = "Capture everything on the custom bus → Firehose → S3"
  event_bus_name = module.eventbridge_bus[0].bus_name

  # Match anything with a source. EventBridge requires at least one filter key.
  event_pattern = jsonencode({
    source = [{ prefix = "" }]
  })
}

resource "aws_cloudwatch_event_target" "catch_all_to_firehose" {
  count          = var.enable_ingestion && var.enable_firehose_archive ? 1 : 0
  rule           = aws_cloudwatch_event_rule.catch_all[0].name
  event_bus_name = module.eventbridge_bus[0].bus_name
  target_id      = "to-firehose"
  arn            = module.firehose_eb_to_s3[0].stream_arn
  role_arn       = aws_iam_role.eb_targets[0].arn
}

# ──────────────────────────────────────────────
# Forwarding rules on the default bus → custom bus.
# Phase 2 forwards aws.guardduty + aws.signin. Add more sources here as needed.
# CloudTrail mgmt events already land in S3 via the trail bucket — no double-archive.
# ──────────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "forward_aws_native" {
  count       = var.enable_ingestion ? 1 : 0
  name        = "${var.project_name}-${var.environment}-forward-aws-native"
  description = "Forward selected AWS-native events from default bus to custom bus"

  event_pattern = jsonencode({
    source = [
      "aws.guardduty",
      "aws.signin",
    ]
  })
}

resource "aws_cloudwatch_event_target" "forward_to_custom_bus" {
  count     = var.enable_ingestion ? 1 : 0
  rule      = aws_cloudwatch_event_rule.forward_aws_native[0].name
  target_id = "to-custom-bus"
  arn       = module.eventbridge_bus[0].bus_arn
  role_arn  = aws_iam_role.eb_targets[0].arn
}

# ──────────────────────────────────────────────
# Phase 3 — Pipeline (DDB + lambdas + Step Functions)
# Reads from the custom bus + R53 resolver CWL group.
# Requires ingestion (custom bus) + r53 resolver qlog to be on.
# ──────────────────────────────────────────────

module "outputs" {
  count  = var.enable_outputs ? 1 : 0
  source = "../modules/outputs"

  project_name = var.project_name
  environment  = var.environment
  alert_email  = var.alert_email

  lambda_src_dir = "${path.root}/../../enrichmentpipeline/src"
}

module "pipeline" {
  count  = var.enable_pipeline && var.enable_ingestion && var.enable_route53_resolver_qlog && var.enable_outputs ? 1 : 0
  source = "../modules/pipeline"

  project_name = var.project_name
  environment  = var.environment

  eb_bus_name = module.eventbridge_bus[0].bus_name
  eb_bus_arn  = module.eventbridge_bus[0].bus_arn

  raw_archive_bucket     = module.raw_archive[0].bucket_name
  raw_archive_bucket_arn = module.raw_archive[0].bucket_arn

  r53_resolver_log_group_name = "/${var.project_name}/${var.environment}/route53-resolver"
  r53_resolver_log_group_arn  = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/${var.project_name}/${var.environment}/route53-resolver"

  lambda_src_dir        = "${path.root}/../../enrichmentpipeline/src"
  statemachine_asl_path = "${path.root}/../../enrichmentpipeline/statemachine/pipeline.asl.json"

  sns_topic_arn         = module.outputs[0].sns_topic_arn
  block_ip_function_arn = module.outputs[0].block_ip_function_arn
}

# ──────────────────────────────────────────────
# Phase 5 — Dashboard API (HTTP API + Lambda → DDB events table)
# ──────────────────────────────────────────────

module "dashboard_api" {
  count  = var.enable_dashboard_api && var.enable_pipeline && var.enable_ingestion && var.enable_route53_resolver_qlog && var.enable_outputs ? 1 : 0
  source = "../modules/dashboard_api"

  project_name = var.project_name
  environment  = var.environment

  events_table_name = module.pipeline[0].events_table_name
  events_table_arn  = module.pipeline[0].events_table_arn

  lambda_src_dir = "${path.root}/../../enrichmentpipeline/src"

  # Pipeline-status inputs (powers GET /api/pipeline)
  sfn_arn               = module.pipeline[0].state_machine_arn
  ipset_name            = module.outputs[0].ipset_name
  ipset_id              = module.outputs[0].ipset_id
  ipset_arn             = module.outputs[0].ipset_arn
  sns_topic_name        = module.outputs[0].sns_topic_name
  eb_bus_name           = module.eventbridge_bus[0].bus_name
  eb_catchall_rule_name = module.pipeline[0].catch_all_rule_name
  lambda_names_for_metrics = [
    module.pipeline[0].dns_detector_function_name,
    module.pipeline[0].persist_function_name,
    module.outputs[0].block_ip_function_name,
  ]
}

# ──────────────────────────────────────────────
# Phase 9 — Threat intel: blacklist DDB + loader (abuse.ch feed) + flow_detector.
# flow_detector subscribes to the VPC flow-log group and publishes HIGH events
# to the custom bus when any VPC ENI talks to/from a blacklisted IP. The
# existing pipeline persists + alerts + blocks. Needs flow logs + the bus.
# ──────────────────────────────────────────────

module "threat_intel" {
  count  = var.enable_threat_intel && var.enable_vpc_flow_logs && var.enable_ingestion ? 1 : 0
  source = "../modules/threat_intel"

  project_name = var.project_name
  environment  = var.environment

  lambda_src_dir = "${path.root}/../../enrichmentpipeline/src"

  eb_bus_name = module.eventbridge_bus[0].bus_name
  eb_bus_arn  = module.eventbridge_bus[0].bus_arn

  vpc_flow_log_group_name = module.vpc_flow_logs[0].log_group_name
  vpc_flow_log_group_arn  = module.vpc_flow_logs[0].log_group_arn
}

data "aws_caller_identity" "current" {}
