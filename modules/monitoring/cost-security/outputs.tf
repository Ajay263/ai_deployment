# Cost Security Module Outputs
# File: modules/monitoring/cost-security/outputs.tf

output "cost_budget_name" {
  description = "Name of the cost budget"
  value       = aws_budgets_budget.ecs_monthly_budget.name
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = aws_cloudtrail.security_trail.arn
}

output "cloudtrail_s3_bucket" {
  description = "Name of the S3 bucket for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs.bucket
}

output "security_alarm_names" {
  description = "List of security-related alarm names"
  value = [
    aws_cloudwatch_metric_alarm.root_account_usage.alarm_name,
    aws_cloudwatch_metric_alarm.failed_logins.alarm_name,
    aws_cloudwatch_metric_alarm.unauthorized_api_calls.alarm_name
  ]
}