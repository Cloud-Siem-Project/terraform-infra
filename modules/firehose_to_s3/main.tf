locals {
  name_prefix = "${var.project_name}-${var.environment}"
  stream_name = "${local.name_prefix}-${var.stream_name_suffix}"
}

# ──────────────────────────────────────────────
# Error log destination — firehose writes failures here
# ──────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "firehose" {
  name              = "/aws/kinesisfirehose/${local.stream_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_stream" "s3_delivery" {
  name           = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.firehose.name
}

# ──────────────────────────────────────────────
# IAM — firehose writes to S3, reads from KMS (not used), publishes CWL errors
# ──────────────────────────────────────────────

data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "firehose" {
  name               = "${local.stream_name}-firehose"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

data "aws_iam_policy_document" "policy" {
  statement {
    sid    = "S3Write"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]
    resources = [
      var.destination_bucket_arn,
      "${var.destination_bucket_arn}/*",
    ]
  }

  statement {
    sid    = "CWLErrors"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.firehose.arn}:*"]
  }
}

resource "aws_iam_role_policy" "firehose" {
  name   = "${local.stream_name}-policy"
  role   = aws_iam_role.firehose.id
  policy = data.aws_iam_policy_document.policy.json
}

# ──────────────────────────────────────────────
# Firehose delivery stream — extended S3 destination, gzip, JSONL
# ──────────────────────────────────────────────

resource "aws_kinesis_firehose_delivery_stream" "main" {
  name        = local.stream_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = var.destination_bucket_arn

    prefix              = var.destination_prefix
    error_output_prefix = "${var.destination_prefix}_errors/"

    buffering_interval = var.buffering_interval
    buffering_size     = var.buffering_size_mb

    compression_format = "GZIP"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = aws_cloudwatch_log_stream.s3_delivery.name
    }
  }

  depends_on = [aws_iam_role_policy.firehose]
}
