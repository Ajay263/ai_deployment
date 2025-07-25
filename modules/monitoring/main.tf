# modules/monitoring/main.tf

# Data sources for existing resources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# modules/monitoring/variables.tf

# CloudWatch log group for ECS events
resource "aws_cloudwatch_log_group" "ecs_events" {
  name              = "/aws/events/ecs"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# CloudWatch log group for application logs
resource "aws_cloudwatch_log_group" "app_logs" {
  for_each = var.applications

  name              = "/ecs/${var.cluster_name}/${each.key}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

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

# IAM role for EventBridge to write to CloudWatch logs
resource "aws_iam_role" "eventbridge_logs_role" {
  name = "${var.cluster_name}-eventbridge-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "eventbridge_logs_policy" {
  name = "${var.cluster_name}-eventbridge-logs-policy"
  role = aws_iam_role.eventbridge_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          aws_cloudwatch_log_group.ecs_events.arn,
          "${aws_cloudwatch_log_group.ecs_events.arn}:*"
        ]
      }
    ]
  })
}

# CloudWatch log metric filter for ECS errors
resource "aws_cloudwatch_log_metric_filter" "ecs_errors" {
  name           = "${var.cluster_name}-ecs-errors"
  log_group_name = aws_cloudwatch_log_group.ecs_events.name

  pattern = jsonencode({
    "$.detail.group" = "*"
    "$.detail.stopCode" = ["TaskFailedToStart", "TaskFailed"]
  }) != null ? jsonencode({
    "$.detail.group" = "*"
    "$.detail.stopCode" = ["TaskFailedToStart", "TaskFailed"]
  }) : <<PATTERN
{
  ($.detail.group = "*" && $.detail.stopCode = "TaskFailedToStart") ||
  ($.detail-type = "ECS Service Action" && ($.detail.eventName = "SERVICE_DEPLOYMENT_FAILED" || $.detail.eventName = "SERVICE_TASK_PLACEMENT_FAILURE" || $.detail.eventName = "SERVICE_STEADY_STATE_TIMEOUT")) ||
  ($.detail-type = "ECS Task State Change" && ($.detail.stoppedReason = "OutOfMemoryError" || $.detail.stoppedReason = "EssentialContainerExited" || $.detail.stoppedReason != "" || $.detail.stopCode = "TaskFailed"))
}
PATTERN

  metric_transformation {
    name      = "ECSErrors"
    namespace = "${var.cluster_name}/ECSEvents"
    value     = "1"
    unit      = "Count"
    dimensions = {
      ClusterName = var.cluster_name
      ServiceName = "$.detail.group"
    }
  }
}

# CloudWatch log metric filter for application errors
resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  for_each = var.applications

  name           = "${var.cluster_name}-${each.key}-errors"
  log_group_name = aws_cloudwatch_log_group.app_logs[each.key].name
  pattern        = "ERROR"

  metric_transformation {
    name      = "ApplicationErrors"
    namespace = "${var.cluster_name}/Applications"
    value     = "1"
    unit      = "Count"
    dimensions = {
      ClusterName     = var.cluster_name
      ApplicationName = each.key
    }
  }
}

# SNS topic for monitoring alerts
resource "aws_sns_topic" "monitoring" {
  name = "${var.cluster_name}-monitoring"

  lambda_success_feedback_role_arn    = aws_iam_role.sns_delivery_status.arn
  lambda_failure_feedback_role_arn    = aws_iam_role.sns_delivery_status.arn
  lambda_success_feedback_sample_rate = 100

  tags = var.tags
}

# SNS topic policy
resource "aws_sns_topic_policy" "monitoring" {
  arn = aws_sns_topic.monitoring.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${var.cluster_name}-monitoring-policy"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarmsToPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.monitoring.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      }
    ]
  })
}

# SNS subscriptions
resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.notification_emails)

  topic_arn = aws_sns_topic.monitoring.arn
  protocol  = "email"
  endpoint  = each.value
}

# IAM role for SNS delivery status logging
resource "aws_iam_role" "sns_delivery_status" {
  name = "${var.cluster_name}-sns-delivery-status"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "sns_delivery_status" {
  name = "${var.cluster_name}-sns-delivery-status"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutMetricFilter",
          "logs:PutRetentionPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sns_delivery_status" {
  role       = aws_iam_role.sns_delivery_status.name
  policy_arn = aws_iam_policy.sns_delivery_status.arn
}

# CloudWatch metric alarms
resource "aws_cloudwatch_metric_alarm" "service_crashes" {
  for_each = var.applications

  alarm_name          = "${var.cluster_name}-${each.key}-service-crashes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "ECSErrors"
  namespace           = "${var.cluster_name}/ECSEvents"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "ECS service ${each.key} crashes detected"
  alarm_actions       = [aws_sns_topic.monitoring.arn]
  ok_actions          = [aws_sns_topic.monitoring.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = "service:${each.key}-service"
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  for_each = var.applications

  alarm_name          = "${var.cluster_name}-${each.key}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_description   = "High CPU utilization for ${each.key} service"
  alarm_actions       = [aws_sns_topic.monitoring.arn]
  ok_actions          = [aws_sns_topic.monitoring.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = "${each.key}-service"
    ClusterName = var.cluster_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "high_memory_utilization" {
  for_each = var.applications

  alarm_name          = "${var.cluster_name}-${each.key}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.memory_threshold
  alarm_description   = "High memory utilization for ${each.key} service"
  alarm_actions       = [aws_sns_topic.monitoring.arn]
  ok_actions          = [aws_sns_topic.monitoring.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = "${each.key}-service"
    ClusterName = var.cluster_name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "application_errors" {
  for_each = var.applications

  alarm_name          = "${var.cluster_name}-${each.key}-app-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApplicationErrors"
  namespace           = "${var.cluster_name}/Applications"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_threshold
  alarm_description   = "High error rate for ${each.key} application"
  alarm_actions       = [aws_sns_topic.monitoring.arn]
  ok_actions          = [aws_sns_topic.monitoring.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName     = var.cluster_name
    ApplicationName = each.key
  }

  tags = var.tags
}

# ALB target group health alarms
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  for_each = var.target_groups

  alarm_name          = "${var.cluster_name}-${each.key}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "0"
  alarm_description   = "Unhealthy targets detected for ${each.key}"
  alarm_actions       = [aws_sns_topic.monitoring.arn]
  ok_actions          = [aws_sns_topic.monitoring.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = each.value
    LoadBalancer = var.load_balancer_arn_suffix
  }

  tags = var.tags
}

# CloudWatch dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.cluster_name}-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            for app_name in keys(var.applications) : [
              "AWS/ECS",
              "CPUUtilization",
              "ServiceName",
              "${app_name}-service",
              "ClusterName",
              var.cluster_name
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = local.region
          title   = "ECS Service CPU Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            for app_name in keys(var.applications) : [
              "AWS/ECS",
              "MemoryUtilization",
              "ServiceName",
              "${app_name}-service",
              "ClusterName",
              var.cluster_name
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = local.region
          title   = "ECS Service Memory Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            for app_name in keys(var.applications) : [
              "${var.cluster_name}/Applications",
              "ApplicationErrors",
              "ApplicationName",
              app_name,
              "ClusterName",
              var.cluster_name
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = local.region
          title   = "Application Errors"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 18
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.ecs_events.name}' | fields @timestamp, detail.group, detail.stopCode, detail.stoppedReason\n| filter detail.stopCode = \"TaskFailedToStart\" or detail.stopCode = \"TaskFailed\"\n| sort @timestamp desc\n| limit 100"
          region  = local.region
          title   = "Recent ECS Task Failures"
          view    = "table"
        }
      }
    ]
  })
}