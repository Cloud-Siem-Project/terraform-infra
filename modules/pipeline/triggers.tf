# ──────────────────────────────────────────────
# CWL subscription filter — R53 resolver group → dns_detector lambda
# ──────────────────────────────────────────────

resource "aws_lambda_permission" "cwl_invoke_dns_detector" {
  statement_id  = "AllowCWLInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dns_detector.function_name
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
  source_arn    = "${var.r53_resolver_log_group_arn}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "r53_to_dns_detector" {
  name            = "${local.dns_detector_name}-filter"
  log_group_name  = var.r53_resolver_log_group_name
  filter_pattern  = "" # subscribe to everything
  destination_arn = aws_lambda_function.dns_detector.arn

  depends_on = [aws_lambda_permission.cwl_invoke_dns_detector]
}

# ──────────────────────────────────────────────
# EventBridge catch-all rule on custom bus → SFN state machine
# Everything that lands on the bus (forwarded aws.signin/guardduty, dns.scored,
# any future producer) gets handled by the pipeline.
# ──────────────────────────────────────────────

data "aws_iam_policy_document" "eb_to_sfn_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eb_to_sfn" {
  name               = "${local.name_prefix}-eb-to-sfn"
  assume_role_policy = data.aws_iam_policy_document.eb_to_sfn_assume.json
}

data "aws_iam_policy_document" "eb_to_sfn_policy" {
  statement {
    sid       = "StartExecution"
    effect    = "Allow"
    actions   = ["states:StartExecution"]
    resources = [aws_sfn_state_machine.pipeline.arn]
  }
}

resource "aws_iam_role_policy" "eb_to_sfn" {
  name   = "${local.name_prefix}-eb-to-sfn"
  role   = aws_iam_role.eb_to_sfn.id
  policy = data.aws_iam_policy_document.eb_to_sfn_policy.json
}

resource "aws_cloudwatch_event_rule" "pipeline_catch_all" {
  name           = "${local.name_prefix}-pipeline-catch-all"
  description    = "Everything on custom bus → pipeline state machine"
  event_bus_name = var.eb_bus_name

  event_pattern = jsonencode({
    source = [{ prefix = "" }]
  })
}

resource "aws_cloudwatch_event_target" "pipeline_sfn" {
  rule           = aws_cloudwatch_event_rule.pipeline_catch_all.name
  event_bus_name = var.eb_bus_name
  target_id      = "pipeline-sfn"
  arn            = aws_sfn_state_machine.pipeline.arn
  role_arn       = aws_iam_role.eb_to_sfn.arn
}
