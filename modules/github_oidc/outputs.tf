output "role_arn" {
  description = "IAM role ARN — set as AWS_ROLE_ARN secret in each GitHub repo"
  value       = aws_iam_role.github_actions.arn
}
