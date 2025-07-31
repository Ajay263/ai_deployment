# environments/staging/outputs.tf
# Staging Environment Outputs

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
  }
}

output "cluster_info" {
  description = "ECS cluster information"
  value = {
    cluster_name = module.ecs.cluster_name
    cluster_arn  = module.ecs.cluster_arn
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

output "alarm_names" {
  description = "List of all CloudWatch alarm names"
  value = concat(
    [for alarm in aws_cloudwatch_metric_alarm.ecs_high_cpu : alarm.alarm_name],
    [for alarm in aws_cloudwatch_metric_alarm.ecs_high_memory : alarm.alarm_name],
    [aws_cloudwatch_metric_alarm.alb_5xx_errors.alarm_name]
  )
}

# ============================================================================
# STAGING SPECIFIC
# ============================================================================

output "staging_info" {
  description = "Staging environment specific information"
  value = {
    environment         = var.environment
    log_retention_days  = var.log_retention_days
    cpu_threshold       = var.cpu_threshold
    memory_threshold    = var.memory_threshold
    alb_5xx_threshold   = var.alb_5xx_threshold
    cost_monitoring     = "enabled"
    backup_retention    = "moderate"
  }
}