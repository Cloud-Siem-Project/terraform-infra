output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  value = aws_sns_topic.alerts.name
}

output "ipset_arn" {
  value = aws_wafv2_ip_set.blocklist.arn
}

output "ipset_id" {
  value = aws_wafv2_ip_set.blocklist.id
}

output "ipset_name" {
  value = aws_wafv2_ip_set.blocklist.name
}

output "block_ip_function_arn" {
  value = aws_lambda_function.block_ip.arn
}

output "block_ip_function_name" {
  value = aws_lambda_function.block_ip.function_name
}

output "email_subscription_pending" {
  description = "True if alert_email was set but the user hasn't confirmed the subscription yet"
  value       = var.alert_email != ""
}
