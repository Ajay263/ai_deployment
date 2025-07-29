# Development Environment Main Configuration

# Data sources
data "aws_secretsmanager_secret" "groq_api_key" {
  name = "groqkey"
}

data "aws_region" "current" {}

# Local values
locals {
  cluster_name = "${var.project_name}-${var.environment}"
  
  common_tags = merge(var.common_tags, {
    Environment = var.environment
  })
}

# Cost and Security Module
module "cost_security" {
  source = "../../modules/monitoring/cost-security"
  
  cluster_name            = local.cluster_name
  notification_emails     = var.notification_emails
  sns_topic_arn          = module.sns.sns_topic_arn
  log_retention_days     = var.log_retention_days
  enable_container_insights = var.enable_container_insights
  tags                   = local.common_tags
}

# ============================================================================
# INFRASTRUCTURE MODULES
# ============================================================================

# VPC Module
module "vpc" {
  source = "../../modules/infra/vpc"
  
  vpc_cidr     = var.vpc_cidr
  num_subnets  = var.num_subnets
  cluster_name = local.cluster_name
  tags         = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/infra/security-groups"
  
  vpc_id       = module.vpc.vpc_id
  cluster_name = local.cluster_name
  allowed_ips  = var.allowed_ips
  tags         = local.common_tags
}

# IAM Module
module "iam" {
  source = "../../modules/infra/iam"
  
  cluster_name = local.cluster_name
  tags         = local.common_tags
}

# ============================================================================
# APPLICATION MODULES
# ============================================================================

# ALB Module
module "alb" {
  source = "../../modules/app/alb"
  
  cluster_name          = local.cluster_name
  alb_security_group_id = module.security_groups.alb_security_group_id
  subnet_ids            = module.vpc.public_subnet_ids
  tags                  = local.common_tags
}

# ECR Module
module "ecr" {
  source = "../../modules/app/ecr"
  
  applications = var.applications
  tags         = local.common_tags
}

# Generate Dockerfile for UI with backend URL
resource "local_file" "dockerfile" {
  content = templatefile("../../modules/app/apps/templates/ui.tftpl", {
    build_args = {
      "backend_url" = module.alb.alb_dns_name
    }
  })
  filename = "../../modules/app/apps/ui/Dockerfile"
}

# ECS Module
module "ecs" {
  source = "../../modules/app/ecs"
  
  depends_on = [local_file.dockerfile]
  
  cluster_name            = local.cluster_name
  applications            = var.applications
  ecr_repositories        = module.ecr.repositories
  execution_role_arn      = module.iam.ecs_execution_role_arn
  app_security_group_id   = module.security_groups.app_security_group_id
  subnet_ids              = module.vpc.public_subnet_ids
  vpc_id                  = module.vpc.vpc_id
  alb_listener_arn        = module.alb.alb_listener_arn
  aws_region              = data.aws_region.current.name
  enable_container_insights = var.enable_container_insights
  tags                    = local.common_tags
}

# ============================================================================
# MONITORING MODULES
# ============================================================================

# CloudWatch Module
module "cloudwatch" {
  source = "../../modules/monitoring/cloudwatch"
  
  cluster_name             = local.cluster_name
  cluster_arn              = module.ecs.cluster_arn
  applications             = {
    for app_name, app_config in var.applications : app_name => {
      name = app_config.app_name
    }
  }
  load_balancer_arn_suffix = module.alb.alb_arn_suffix
  log_retention_days       = var.log_retention_days
  tags                     = local.common_tags
}

# SNS Module
module "sns" {
  source = "../../modules/monitoring/sns"
  
  cluster_name      = local.cluster_name
  notification_emails = var.notification_emails
  slack_webhook_url = var.slack_webhook_url
  tags              = local.common_tags
}

# ============================================================================
# CLOUDWATCH ALARMS
# ============================================================================

# ECS Performance Alarms
resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  for_each = var.applications

  alarm_name          = "${local.cluster_name}-${each.key}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "High CPU utilization for ${each.key} service (>${var.cpu_threshold}%)"
  alarm_actions       = [module.sns.sns_topic_arn]
  ok_actions          = [module.sns.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = "${each.key}-service"
    ClusterName = local.cluster_name
  }
  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_high_memory" {
  for_each = var.applications

  alarm_name          = "${local.cluster_name}-${each.key}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.memory_threshold
  alarm_description   = "High memory utilization for ${each.key} service (>${var.memory_threshold}%)"
  alarm_actions       = [module.sns.sns_topic_arn]
  ok_actions          = [module.sns.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = "${each.key}-service"
    ClusterName = local.cluster_name
  }
  tags = local.common_tags
}

# ALB 5xx Errors
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${local.cluster_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  alarm_description   = "High 5xx error rate from ALB (>${var.alb_5xx_threshold} errors)"
  alarm_actions       = [module.sns.sns_topic_arn]
  ok_actions          = [module.sns.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = module.alb.alb_arn_suffix
  }
  tags = local.common_tags
}