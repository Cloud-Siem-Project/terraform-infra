locals {
  name_prefix = "${var.project_name}-${var.environment}"

  sns_topic_name = "${local.name_prefix}-alerts"
  ipset_name     = "${local.name_prefix}-blocklist"
  block_ip_name  = "${local.name_prefix}-block-ip"
}

# ──────────────────────────────────────────────
# SNS — alerts topic
# Email subscription only created when var.alert_email is non-empty. The user
# needs to click the confirmation link in their inbox before SNS will deliver.
# ──────────────────────────────────────────────

resource "aws_sns_topic" "alerts" {
  name = local.sns_topic_name
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ──────────────────────────────────────────────
# WAFv2 IPSet — REGIONAL scope. Empty to start. block_ip lambda appends to it.
# Not attached to a WebACL yet (deferred — needs us-east-1 + cloudfront wiring).
# ──────────────────────────────────────────────

resource "aws_wafv2_ip_set" "blocklist" {
  name               = local.ipset_name
  description        = "CloudGuard DNS - sources blocked by HIGH severity events"
  scope              = var.ipset_scope
  ip_address_version = "IPV4"
  addresses          = []

  # block_ip lambda mutates this set out-of-band. Don't fight it on every plan.
  lifecycle {
    ignore_changes = [addresses]
  }
}

# ──────────────────────────────────────────────
# block_ip lambda — SFN target. Appends to the IPSet.
# ──────────────────────────────────────────────

data "archive_file" "block_ip" {
  type        = "zip"
  source_dir  = "${var.lambda_src_dir}/block_ip"
  output_path = "${path.module}/.build/block_ip.zip"
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "block_ip" {
  name               = "${local.block_ip_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_cloudwatch_log_group" "block_ip" {
  name              = "/aws/lambda/${local.block_ip_name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "block_ip" {
  statement {
    sid       = "CWLWrite"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.block_ip.arn}:*"]
  }

  statement {
    sid    = "WAFv2IPSet"
    effect = "Allow"
    actions = [
      "wafv2:GetIPSet",
      "wafv2:UpdateIPSet",
    ]
    resources = [aws_wafv2_ip_set.blocklist.arn]
  }
}

resource "aws_iam_role_policy" "block_ip" {
  name   = "${local.block_ip_name}-policy"
  role   = aws_iam_role.block_ip.id
  policy = data.aws_iam_policy_document.block_ip.json
}

resource "aws_lambda_function" "block_ip" {
  function_name    = local.block_ip_name
  role             = aws_iam_role.block_ip.arn
  runtime          = var.lambda_runtime
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.block_ip.output_path
  source_code_hash = data.archive_file.block_ip.output_base64sha256
  timeout          = 15
  memory_size      = 128

  environment {
    variables = {
      IPSET_NAME  = aws_wafv2_ip_set.blocklist.name
      IPSET_ID    = aws_wafv2_ip_set.blocklist.id
      IPSET_SCOPE = var.ipset_scope
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.block_ip,
    aws_iam_role_policy.block_ip,
  ]
}
