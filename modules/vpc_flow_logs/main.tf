locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_cloudwatch_log_group" "flow" {
  name              = "/${var.project_name}/${var.environment}/vpc-flow"
  retention_in_days = var.retention_days
}

# IAM role assumed by the VPC Flow Logs service to write into CWL
data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flow" {
  name               = "${local.name_prefix}-vpc-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

data "aws_iam_policy_document" "publish" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = [
      aws_cloudwatch_log_group.flow.arn,
      "${aws_cloudwatch_log_group.flow.arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "flow" {
  name   = "${local.name_prefix}-vpc-flow-logs-publish"
  role   = aws_iam_role.flow.id
  policy = data.aws_iam_policy_document.publish.json
}

resource "aws_flow_log" "vpc" {
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow.arn
  iam_role_arn         = aws_iam_role.flow.arn
  traffic_type         = var.traffic_type
  vpc_id               = var.vpc_id
}
