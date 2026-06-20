output "lambda_function_name" {
  value = aws_lambda_function.api.function_name
}

output "api_id" {
  value = aws_apigatewayv2_api.api.id
}

output "api_endpoint" {
  description = "Full execute-api URL (https://<id>.execute-api.<region>.amazonaws.com)"
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "api_domain" {
  description = "Just the host portion — use as CloudFront origin domain"
  value       = replace(aws_apigatewayv2_api.api.api_endpoint, "https://", "")
}
