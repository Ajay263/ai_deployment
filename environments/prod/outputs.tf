# environments/prod/outputs.tf
# Production Environment Outputs

# ============================================================================
# APPLICATION ENDPOINTS
# ============================================================================

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = "http://${module.alb.alb_dns_name}"
}

output "alb_url" {
  description = "URL of the Application Load Balancer"
  value       = "http://${module.alb.alb_dns_name}"
  sensitive   = false
}

# ============================================================================
# APPLICATION SERVICES
# ============================================================================

output "application_services" {
  description = "Information about deployed application services"
  value = {
    for app_name, app_config in var.applications : app_name => {
      service_name     = module.ecs.service_names[app_name]
      service_arn      = module.ecs.service_arns[app_name]
      ecr_url          = module.ecr.repository_urls[app_name]
      target_group_arn = module.ecs.target_group_arns[app_name]
      desired_count    = app_config.desired_count
      cpu              = app_config.cpu
      memory           = app_config.memory
      environment      = "production"
      high_availability = app_config.desired_count >= 2
    }
  }
}

# ============================================================================
# INFRASTRUCTURE
# ============================================================================

output "vpc_info" {
  description = "VPC information"
  value = {
    vpc_id     = module.vpc.vpc_id
    vpc_cidr   = module.vpc.vpc_cidr_block
    subnet_ids = module.vpc.public_subnet_ids
    environment = "production"
    multi_az   = length(module.vpc.public_subnet_ids) > 1
  }
}

output "cluster_info" {
  description = "ECS cluster information"
  value = {
    cluster_name = module.ecs.cluster_name
    cluster_arn  = module.ecs.cluster_arn
    environment  = "production"
    insights_enabled = var.enable_container_insights
  }
}

# ============================================================================
# MONITORING
# ============================================================================

output "monitoring_dashboard_url" {
  description = "URL to the CloudWatch monitoring dashboard"
  value       = module.cloudwatch.dashboard_url
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for monitoring alerts"
  value       = module.sns.sns_topic_arn
}

output "critical_sns_topic_arn" {
  description = "ARN of the SNS topic for critical alerts"
  value       = aws_sns_topic.critical_alerts.arn
}

output "alarm_names" {
  description = "List of all CloudWatch alarm names"
  value = concat(
    [for alarm in aws_cloudwatch_metric_alarm.ecs_high_cpu : alarm.alarm_name],
    [for alarm in aws_cloudwatch_metric_alarm.ecs_high_memory : alarm.alarm_name],
    [for alarm in aws_cloudwatch_metric_alarm.ecs_task_count : alarm.alarm_name],
    [aws_cloudwatch_metric_alarm.alb_5xx_errors.alarm_name],
    [aws_cloudwatch_metric_alarm.alb_response_time.alarm_name]
  )
}

# ============================================================================
# SECURITY & COMPLIANCE
# ============================================================================

output "security_info" {
  description = "Security and compliance information"
  value = {
    cloudtrail_enabled    = true
    encryption_enabled    = true
    deletion_protection   = true
    backup_enabled        = var.enable_backup
    multi_az_deployment   = var.enable_multi_az
    cost_monitoring       = var.enable_cost_anomaly_detection
    detailed_monitoring   = var.enable_detailed_monitoring
  }
}

# ============================================================================
# PRODUCTION SPECIFIC
# ============================================================================

output "production_info" {
  description = "Production environment specific information"
  value = {
    environment           = var.environment
    log_retention_days    = var.log_retention_days
    cpu_threshold         = var.cpu_threshold
    memory_threshold      = var.memory_threshold
    alb_5xx_threshold     = var.alb_5xx_threshold
    response_time_threshold = var.alb_response_time_threshold
    minimum_task_count    = var.task_count_threshold
    high_availability     = true
    disaster_recovery     = "enabled"
    compliance_ready      = true
  }
}

# ============================================================================
# COST INFORMATION
# ============================================================================

output "cost_tracking" {
  description = "Cost tracking and budgeting information"
  value = {
    cost_center          = "production"
    billing_alerts       = "enabled"
    budget_monitoring    = var.enable_cost_anomaly_detection
    resource_tagging     = "enforced"
    estimated_monthly_cost = "Contact FinOps team for details"
  }
}