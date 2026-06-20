data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  ti_table_name      = "${local.name_prefix}-threat-intel"
  loader_name        = "${local.name_prefix}-ti-loader"
  flow_detector_name = "${local.name_prefix}-flow-detector"
}

# ──────────────────────────────────────────────
# Lambda packaging — zip each src dir at plan time (matches pipeline module)
# ──────────────────────────────────────────────

data "archive_file" "ti_loader" {
  type        = "zip"
  source_dir  = "${var.lambda_src_dir}/ti_loader"
  output_path = "${path.module}/.build/ti_loader.zip"
}

data "archive_file" "flow_detector" {
  type        = "zip"
  source_dir  = "${var.lambda_src_dir}/flow_detector"
  output_path = "${path.module}/.build/flow_detector.zip"
}
