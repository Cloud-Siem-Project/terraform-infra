output "threat_intel_table_name" {
  value = aws_dynamodb_table.threat_intel.name
}

output "threat_intel_table_arn" {
  value = aws_dynamodb_table.threat_intel.arn
}

output "loader_function_name" {
  value = aws_lambda_function.loader.function_name
}

output "flow_detector_function_name" {
  value = aws_lambda_function.flow_detector.function_name
}

output "seed_result" {
  description = "Result payload from the apply-time seed invocation"
  value       = try(jsondecode(aws_lambda_invocation.seed.result), null)
}
