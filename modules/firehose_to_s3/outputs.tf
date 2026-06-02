output "stream_arn" {
  description = "Firehose delivery stream ARN — use as EB target"
  value       = aws_kinesis_firehose_delivery_stream.main.arn
}

output "stream_name" {
  description = "Firehose delivery stream name"
  value       = aws_kinesis_firehose_delivery_stream.main.name
}

output "error_log_group" {
  description = "CWL group where Firehose writes delivery failures"
  value       = aws_cloudwatch_log_group.firehose.name
}
