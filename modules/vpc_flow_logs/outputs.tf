output "log_group_name" {
  description = "Name of the VPC Flow Logs CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.flow.name
}

output "log_group_arn" {
  description = "ARN of the VPC Flow Logs CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.flow.arn
}

output "flow_log_id" {
  description = "ID of the aws_flow_log resource"
  value       = aws_flow_log.vpc.id
}
