# ──────────────────────────────────────────────
# Shared lambda assume-role policy
# ──────────────────────────────────────────────

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

# ══════════════════════════════════════════════
# ti_loader — fetches the abuse.ch feed, writes IPs to the blacklist table.
# Runs outside any VPC so it has plain internet egress to reach the feed.
# ══════════════════════════════════════════════

resource "aws_iam_role" "loader" {
  name               = "${local.loader_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_cloudwatch_log_group" "loader" {
  name              = "/aws/lambda/${local.loader_name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "loader_policy" {
  statement {
    sid       = "CWLWrite"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.loader.arn}:*"]
  }

  statement {
    sid    = "DDBWrite"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:BatchWriteItem",
    ]
    resources = [aws_dynamodb_table.threat_intel.arn]
  }

  # capture the downloaded feed snapshot to the evidence bucket (when wired)
  dynamic "statement" {
    for_each = var.evidence_bucket_arn != "" ? [1] : []
    content {
      sid       = "EvidenceWrite"
      effect    = "Allow"
      actions   = ["s3:PutObject"]
      resources = ["${var.evidence_bucket_arn}/*"]
    }
  }
}

resource "aws_iam_role_policy" "loader" {
  name   = "${local.loader_name}-policy"
  role   = aws_iam_role.loader.id
  policy = data.aws_iam_policy_document.loader_policy.json
}

resource "aws_lambda_function" "loader" {
  function_name    = local.loader_name
  role             = aws_iam_role.loader.arn
  runtime          = var.lambda_runtime
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.ti_loader.output_path
  source_code_hash = data.archive_file.ti_loader.output_base64sha256
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      DDB_TABLE       = aws_dynamodb_table.threat_intel.name
      FEED_URL        = var.feed_url
      FEED_SOURCE     = var.feed_source
      TTL_DAYS        = tostring(var.feed_ttl_days)
      SEED_IPS        = join(",", var.seed_ips)
      EVIDENCE_BUCKET = var.evidence_bucket_name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.loader,
    aws_iam_role_policy.loader,
  ]
}

# Seed the table at apply time — one synchronous invoke once the function + IAM
# exist. Re-runs whenever the loader code changes (source hash in input).
resource "aws_lambda_invocation" "seed" {
  function_name = aws_lambda_function.loader.function_name

  input = jsonencode({
    trigger     = "terraform-seed"
    source_hash = data.archive_file.ti_loader.output_base64sha256
  })

  depends_on = [aws_iam_role_policy.loader]
}

# ══════════════════════════════════════════════
# flow_detector — CWL subscription target on the VPC flow-log group. Matches
# flows against the blacklist, publishes HIGH events to the custom EB bus.
# ══════════════════════════════════════════════

resource "aws_iam_role" "flow_detector" {
  name               = "${local.flow_detector_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_cloudwatch_log_group" "flow_detector" {
  name              = "/aws/lambda/${local.flow_detector_name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "flow_detector_policy" {
  statement {
    sid       = "CWLWrite"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.flow_detector.arn}:*"]
  }

  statement {
    sid       = "DDBRead"
    effect    = "Allow"
    actions   = ["dynamodb:Scan"]
    resources = [aws_dynamodb_table.threat_intel.arn]
  }

  statement {
    sid       = "PutEventsToBus"
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = [var.eb_bus_arn]
  }
}

resource "aws_iam_role_policy" "flow_detector" {
  name   = "${local.flow_detector_name}-policy"
  role   = aws_iam_role.flow_detector.id
  policy = data.aws_iam_policy_document.flow_detector_policy.json
}

resource "aws_lambda_function" "flow_detector" {
  function_name    = local.flow_detector_name
  role             = aws_iam_role.flow_detector.arn
  runtime          = var.lambda_runtime
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.flow_detector.output_path
  source_code_hash = data.archive_file.flow_detector.output_base64sha256
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      DDB_TABLE          = aws_dynamodb_table.threat_intel.name
      EB_BUS_NAME        = var.eb_bus_name
      BLACKLIST_TTL_SECS = tostring(var.blacklist_cache_secs)
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.flow_detector,
    aws_iam_role_policy.flow_detector,
  ]
}
