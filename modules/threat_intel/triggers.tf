# ──────────────────────────────────────────────
# ti_loader refresh schedule — EventBridge rate rule on the default bus.
# ──────────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "loader_schedule" {
  name                = "${local.loader_name}-schedule"
  description         = "Refresh the threat-intel blacklist from the feed"
  schedule_expression = var.refresh_schedule
}

resource "aws_cloudwatch_event_target" "loader_schedule" {
  rule      = aws_cloudwatch_event_rule.loader_schedule.name
  target_id = "ti-loader"
  arn       = aws_lambda_function.loader.arn
}

resource "aws_lambda_permission" "events_invoke_loader" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.loader.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.loader_schedule.arn
}

# ──────────────────────────────────────────────
# CWL subscription filter — VPC flow-log group → flow_detector lambda.
# ──────────────────────────────────────────────

resource "aws_lambda_permission" "cwl_invoke_flow_detector" {
  statement_id  = "AllowCWLInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.flow_detector.function_name
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
  source_arn    = "${var.vpc_flow_log_group_arn}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "flow_to_detector" {
  name            = "${local.flow_detector_name}-filter"
  log_group_name  = var.vpc_flow_log_group_name
  filter_pattern  = "" # subscribe to everything; matching happens in the lambda
  destination_arn = aws_lambda_function.flow_detector.arn

  depends_on = [aws_lambda_permission.cwl_invoke_flow_detector]
}
