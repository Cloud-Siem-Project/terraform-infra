locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# CloudWatch destination for VPC DNS queries. This is where DGA / DNS-tunneling
# signals show up — every name an EC2 instance in the VPC resolves.
resource "aws_cloudwatch_log_group" "resolver" {
  name              = "/${var.project_name}/${var.environment}/route53-resolver"
  retention_in_days = var.retention_days
}

# CWL resource policy — required so the Route53 Resolver service can write
# query logs into this log group. Without this the resolver config validates
# but no events ever land.
data "aws_iam_policy_document" "resolver_to_cwl" {
  statement {
    sid    = "AllowRoute53ResolverToWriteLogs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["route53resolver.amazonaws.com"]
    }

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["${aws_cloudwatch_log_group.resolver.arn}:*"]
  }
}

resource "aws_cloudwatch_log_resource_policy" "resolver" {
  policy_name     = "${local.name_prefix}-resolver-qlog"
  policy_document = data.aws_iam_policy_document.resolver_to_cwl.json
}

resource "aws_route53_resolver_query_log_config" "main" {
  name            = "${local.name_prefix}-resolver-qlog"
  destination_arn = aws_cloudwatch_log_group.resolver.arn

  depends_on = [aws_cloudwatch_log_resource_policy.resolver]
}

resource "aws_route53_resolver_query_log_config_association" "main" {
  resolver_query_log_config_id = aws_route53_resolver_query_log_config.main.id
  resource_id                  = var.vpc_id
}
