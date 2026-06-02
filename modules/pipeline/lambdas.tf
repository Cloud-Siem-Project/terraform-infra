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

# ──────────────────────────────────────────────
# dns_detector — CWL subscription target, publishes scored events to EB bus
# ──────────────────────────────────────────────

resource "aws_iam_role" "dns_detector" {
  name               = "${local.dns_detector_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_cloudwatch_log_group" "dns_detector" {
  name              = "/aws/lambda/${local.dns_detector_name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "dns_detector_policy" {
  statement {
    sid       = "CWLWrite"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.dns_detector.arn}:*"]
  }

  statement {
    sid       = "PutEventsToBus"
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = [var.eb_bus_arn]
  }
}

resource "aws_iam_role_policy" "dns_detector" {
  name   = "${local.dns_detector_name}-policy"
  role   = aws_iam_role.dns_detector.id
  policy = data.aws_iam_policy_document.dns_detector_policy.json
}

resource "aws_lambda_function" "dns_detector" {
  function_name    = local.dns_detector_name
  role             = aws_iam_role.dns_detector.arn
  runtime          = var.lambda_runtime
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.dns_detector.output_path
  source_code_hash = data.archive_file.dns_detector.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_mb

  environment {
    variables = {
      EB_BUS_NAME = var.eb_bus_name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.dns_detector,
    aws_iam_role_policy.dns_detector,
  ]
}

# ──────────────────────────────────────────────
# persist — SFN target, writes event to DDB + S3 raw archive
# ──────────────────────────────────────────────

resource "aws_iam_role" "persist" {
  name               = "${local.persist_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_cloudwatch_log_group" "persist" {
  name              = "/aws/lambda/${local.persist_name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "persist_policy" {
  statement {
    sid       = "CWLWrite"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.persist.arn}:*"]
  }

  statement {
    sid       = "DDBWrite"
    effect    = "Allow"
    actions   = ["dynamodb:PutItem", "dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.events.arn]
  }

  statement {
    sid       = "S3Write"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${var.raw_archive_bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "persist" {
  name   = "${local.persist_name}-policy"
  role   = aws_iam_role.persist.id
  policy = data.aws_iam_policy_document.persist_policy.json
}

resource "aws_lambda_function" "persist" {
  function_name    = local.persist_name
  role             = aws_iam_role.persist.arn
  runtime          = var.lambda_runtime
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.persist.output_path
  source_code_hash = data.archive_file.persist.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_mb

  environment {
    variables = {
      DDB_TABLE  = aws_dynamodb_table.events.name
      RAW_BUCKET = var.raw_archive_bucket
      RAW_PREFIX = "eb/"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.persist,
    aws_iam_role_policy.persist,
  ]
}
