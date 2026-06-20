output "events_table_name" {
  value = aws_dynamodb_table.events.name
}

output "events_table_arn" {
  value = aws_dynamodb_table.events.arn
}

output "dns_detector_function_name" {
  value = aws_lambda_function.dns_detector.function_name
}

output "persist_function_name" {
  value = aws_lambda_function.persist.function_name
}

output "state_machine_arn" {
  value = aws_sfn_state_machine.pipeline.arn
}

output "state_machine_name" {
  value = aws_sfn_state_machine.pipeline.name
}

output "catch_all_rule_name" {
  value = aws_cloudwatch_event_rule.pipeline_catch_all.name
}
