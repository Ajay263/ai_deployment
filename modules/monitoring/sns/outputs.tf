# SNS Module Outputs

output "sns_topic_arn" {
  description = "ARN of the SNS topic for monitoring alerts"
  value       = aws_sns_topic.monitoring.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for monitoring alerts"
  value       = aws_sns_topic.monitoring.name
}

output "sns_subscriptions" {
  description = "Map of SNS subscription ARNs"
  value = {
    email = { for k, v in aws_sns_topic_subscription.email : k => v.arn }
    slack = try(aws_sns_topic_subscription.slack[0].arn, null)
  }
}