output "bus_name" {
  description = "Custom EventBridge bus name"
  value       = aws_cloudwatch_event_bus.main.name
}

output "bus_arn" {
  description = "Custom EventBridge bus ARN"
  value       = aws_cloudwatch_event_bus.main.arn
}

output "archive_name" {
  description = "Archive name"
  value       = aws_cloudwatch_event_archive.main.name
}
