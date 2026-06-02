data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  dns_detector_name = "${local.name_prefix}-dns-detector"
  persist_name      = "${local.name_prefix}-persist"
  sfn_name          = "${local.name_prefix}-pipeline"
  ddb_table_name    = "${local.name_prefix}-events"
}

# ──────────────────────────────────────────────
# Lambda packaging — zip each src dir into a build artifact at plan time
# ──────────────────────────────────────────────

data "archive_file" "dns_detector" {
  type        = "zip"
  source_dir  = "${var.lambda_src_dir}/dns_detector"
  output_path = "${path.module}/.build/dns_detector.zip"
}

data "archive_file" "persist" {
  type        = "zip"
  source_dir  = "${var.lambda_src_dir}/persist"
  output_path = "${path.module}/.build/persist.zip"
}
