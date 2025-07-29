# CloudWatch Module Outputs

output "log_groups" {
  description = "Map of CloudWatch log group names"
  value = {
    ecs_events = aws_cloudwatch_log_group.ecs_events.name
    alb_logs   = aws_cloudwatch_log_group.alb_logs.name
    app_logs   = { for k, v in aws_cloudwatch_log_group.app_logs : k => v.name }
  }
}

output "dashboard_url" {
  description = "URL to the comprehensive CloudWatch dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.comprehensive_monitoring.dashboard_name}"
}

output "metric_filter_names" {
  description = "Names of all metric filters created"
  value = concat(
    [aws_cloudwatch_log_metric_filter.ecs_task_failures.name],
    [for filter in aws_cloudwatch_log_metric_filter.app_errors : filter.name],
    try([aws_cloudwatch_log_metric_filter.flask_5xx_errors[0].name], [])
  )
}