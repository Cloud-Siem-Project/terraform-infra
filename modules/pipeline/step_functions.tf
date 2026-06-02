# ──────────────────────────────────────────────
# Step Functions state machine — orchestrates persist + severity branching
# ──────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "sfn" {
  name              = "/aws/vendedlogs/states/${local.sfn_name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "sfn_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sfn" {
  name               = "${local.sfn_name}-role"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume.json
}

data "aws_iam_policy_document" "sfn_policy" {
  statement {
    sid    = "InvokeLambdas"
    effect = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      aws_lambda_function.persist.arn, "${aws_lambda_function.persist.arn}:*",
      var.block_ip_function_arn, "${var.block_ip_function_arn}:*",
    ]
  }

  statement {
    sid       = "PublishSNS"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.sns_topic_arn]
  }

  # Per Step Functions docs, vended-logs delivery needs these wildcarded.
  statement {
    sid    = "CWLDeliver"
    effect = "Allow"
    actions = [
      "logs:CreateLogDelivery",
      "logs:GetLogDelivery",
      "logs:UpdateLogDelivery",
      "logs:DeleteLogDelivery",
      "logs:ListLogDeliveries",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DescribeLogGroups",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "sfn" {
  name   = "${local.sfn_name}-policy"
  role   = aws_iam_role.sfn.id
  policy = data.aws_iam_policy_document.sfn_policy.json
}

resource "aws_sfn_state_machine" "pipeline" {
  name     = local.sfn_name
  role_arn = aws_iam_role.sfn.arn
  type     = "STANDARD"

  definition = templatefile(var.statemachine_asl_path, {
    persist_lambda_arn    = aws_lambda_function.persist.arn
    sns_topic_arn         = var.sns_topic_arn
    block_ip_function_arn = var.block_ip_function_arn
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sfn.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  depends_on = [aws_iam_role_policy.sfn]
}
