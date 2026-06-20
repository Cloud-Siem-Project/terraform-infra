locals {
  name_prefix    = "${var.project_name}-${var.environment}"
  lambda_name    = "${local.name_prefix}-dashboard-api"
  api_name       = "${local.name_prefix}-dashboard"
}

# ──────────────────────────────────────────────
# dashboard_api lambda — reads DDB, returns JSON
# ──────────────────────────────────────────────

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${var.lambda_src_dir}/dashboard_api"
  output_path = "${path.module}/.build/dashboard_api.zip"
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

resource "aws_iam_role" "lambda" {
  name               = "${local.lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "lambda" {
  statement {
    sid       = "CWLWrite"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.lambda.arn}:*"]
  }

  statement {
    sid       = "DDBRead"
    effect    = "Allow"
    actions   = ["dynamodb:Scan", "dynamodb:Query", "dynamodb:GetItem"]
    resources = [var.events_table_arn]
  }

  # Optional perms — only added when the corresponding var is provided.
  dynamic "statement" {
    for_each = var.sfn_arn == "" ? [] : [1]
    content {
      sid       = "SFNRead"
      effect    = "Allow"
      actions   = ["states:ListExecutions", "states:DescribeStateMachine"]
      resources = [var.sfn_arn]
    }
  }

  dynamic "statement" {
    for_each = var.ipset_arn == "" ? [] : [1]
    content {
      sid       = "WAFRead"
      effect    = "Allow"
      actions   = ["wafv2:GetIPSet"]
      resources = [var.ipset_arn]
    }
  }

  # CloudWatch metric reads don't support resource-level scoping for
  # GetMetricStatistics — has to be "*".
  statement {
    sid       = "CWMetricsRead"
    effect    = "Allow"
    actions   = ["cloudwatch:GetMetricStatistics"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${local.lambda_name}-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_lambda_function" "api" {
  function_name    = local.lambda_name
  role             = aws_iam_role.lambda.arn
  runtime          = var.lambda_runtime
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_mb

  environment {
    variables = {
      DDB_TABLE      = var.events_table_name
      SFN_ARN        = var.sfn_arn
      IPSET_NAME     = var.ipset_name
      IPSET_ID       = var.ipset_id
      IPSET_SCOPE    = var.ipset_scope
      SNS_TOPIC_NAME = var.sns_topic_name
      EB_BUS_NAME    = var.eb_bus_name
      EB_RULE_NAME   = var.eb_catchall_rule_name
      LAMBDA_NAMES   = join(",", var.lambda_names_for_metrics)
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy.lambda,
  ]
}

# ──────────────────────────────────────────────
# API Gateway v2 HTTP API
# Stage = $default (auto-deployed, no path prefix in invoke URL)
# Single route: GET /api/events
# ──────────────────────────────────────────────

resource "aws_apigatewayv2_api" "api" {
  name          = local.api_name
  protocol_type = "HTTP"
  description   = "CloudGuard DNS dashboard API"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_events" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /api/events"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_pipeline" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /api/pipeline"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
