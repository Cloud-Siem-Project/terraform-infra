output "log_group_name" {
  description = "CWL group name for resolver query logs"
  value       = aws_cloudwatch_log_group.resolver.name
}

output "log_group_arn" {
  description = "CWL group ARN for resolver query logs"
  value       = aws_cloudwatch_log_group.resolver.arn
}

output "query_log_config_id" {
  description = "ID of the resolver query log config"
  value       = aws_route53_resolver_query_log_config.main.id
}
