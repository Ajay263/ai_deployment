# modules/monitoring/outputs.tf

output "sns_topic_arn" {
  description = "ARN of the SNS topic for monitoring alerts"
  value       = aws_sns_topic.monitoring.arn
}

output "cloudwatch_log_groups" {
  description = "Map of CloudWatch log group names for applications"
  value = {
    ecs_events = aws_cloudwatch_log_group.ecs_events.name
    app_logs   = { for k, v in aws_cloudwatch_log_group.app_logs : k => v.name }
  }
}

output "dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "alarm_names" {
  description = "List of all alarm names created"
  value = concat(
    [for alarm in aws_cloudwatch_metric_alarm.service_crashes : alarm.alarm_name],
    [for alarm in aws_cloudwatch_metric_alarm.high_cpu_utilization : alarm.alarm_name],
    [for alarm in aws_cloudwatch_metric_alarm.high_memory_utilization : alarm.alarm_name],
    [for alarm in aws_cloudwatch_metric_alarm.application_errors : alarm.alarm_name],
    [for alarm in aws_cloudwatch_metric_alarm.unhealthy_targets : alarm.alarm_name]
  )
}