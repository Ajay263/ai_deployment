# CloudWatch Module - Extracted from monitoring main.tf

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# ============================================================================
# LOG GROUPS
# ============================================================================

# CloudWatch log group for ECS events
resource "aws_cloudwatch_log_group" "ecs_events" {
  name              = "/aws/events/ecs"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# CloudWatch log group for application logs
resource "aws_cloudwatch_log_group" "app_logs" {
  for_each = var.applications

  name              = "/ecs/${var.cluster_name}/${each.key}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# CloudWatch log group for ALB logs
resource "aws_cloudwatch_log_group" "alb_logs" {
  name              = "/aws/applicationelb/${var.cluster_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# ============================================================================
# EVENT BRIDGE SETUP
# ============================================================================

# EventBridge rule for ECS events
resource "aws_cloudwatch_event_rule" "ecs_events" {
  name        = "${var.cluster_name}-ecs-events"
  description = "Capture all ECS events for cluster ${var.cluster_name}"

  event_pattern = jsonencode({
    source = ["aws.ecs"]
    detail = {
      clusterArn = [var.cluster_arn]
    }
  })
  tags = var.tags
}

# EventBridge target to send events to CloudWatch logs
resource "aws_cloudwatch_event_target" "logs" {
  rule      = aws_cloudwatch_event_rule.ecs_events.name
  target_id = "send-to-cloudwatch"
  arn       = aws_cloudwatch_log_group.ecs_events.arn
}

# Resource policy to allow EventBridge to write to CloudWatch Logs
resource "aws_cloudwatch_log_resource_policy" "eventbridge_logs_policy" {
  policy_name = "${var.cluster_name}-eventbridge-logs-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EventBridgeLogsPolicy"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ecs_events.arn}:*"
      }
    ]
  })
}

# ============================================================================
# METRIC FILTERS
# ============================================================================

# ECS Task State Changes
resource "aws_cloudwatch_log_metric_filter" "ecs_task_failures" {
  name           = "${var.cluster_name}-ecs-task-failures"
  log_group_name = aws_cloudwatch_log_group.ecs_events.name
  pattern        = "\"ECS Task State Change\""

  metric_transformation {
    name      = "ECSTaskStateChanges"
    namespace = "${var.cluster_name}/ECS/Events"
    value     = "1"
    unit      = "Count"
  }
}

# Application Error Metrics
resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  for_each = var.applications

  name           = "${var.cluster_name}-${each.key}-errors"
  log_group_name = aws_cloudwatch_log_group.app_logs[each.key].name
  pattern        = "ERROR"

  metric_transformation {
    name      = "ApplicationErrors"
    namespace = "${var.cluster_name}/Applications/${each.key}"
    value     = "1"
    unit      = "Count"
  }
}

# Flask 5xx Errors (for API service)
resource "aws_cloudwatch_log_metric_filter" "flask_5xx_errors" {
  count = contains(keys(var.applications), "api") ? 1 : 0

  name           = "${var.cluster_name}-api-5xx-errors"
  log_group_name = aws_cloudwatch_log_group.app_logs["api"].name
  pattern        = "[timestamp, level=\"ERROR\", ..., status_code=5*]"

  metric_transformation {
    name      = "Flask5xxErrors"
    namespace = "${var.cluster_name}/Applications/api"
    value     = "1"
    unit      = "Count"
  }
}

# ============================================================================
# CLOUDWATCH DASHBOARD
# ============================================================================

resource "aws_cloudwatch_dashboard" "comprehensive_monitoring" {
  dashboard_name = "${var.cluster_name}-comprehensive-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      # ECS CPU and Memory Overview
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            for app_name in keys(var.applications) : [
              "AWS/ECS", "CPUUtilization", "ServiceName", "${app_name}-service", "ClusterName", var.cluster_name
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = local.region
          title   = "ECS CPU Utilization (%)"
          period  = 300
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            for app_name in keys(var.applications) : [
              "AWS/ECS", "MemoryUtilization", "ServiceName", "${app_name}-service", "ClusterName", var.cluster_name
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = local.region
          title   = "ECS Memory Utilization (%)"
          period  = 300
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      # ALB Performance Metrics
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.load_balancer_arn_suffix],
            [".", "HTTPCode_ELB_2XX_Count", ".", "."],
            [".", "HTTPCode_ELB_4XX_Count", ".", "."],
            [".", "HTTPCode_ELB_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = local.region
          title   = "ALB Request Count & HTTP Status Codes"
          period  = 300
        }
      }
    ]
  })
}