# SNS Module - Extracted from monitoring main.tf

# Data sources
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# ============================================================================
# SNS TOPIC AND SUBSCRIPTIONS
# ============================================================================

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

# SNS subscriptions for email notifications
resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.notification_emails)

  topic_arn = aws_sns_topic.monitoring.arn
  protocol  = "email"
  endpoint  = each.value
}

# Optional Slack webhook subscription
resource "aws_sns_topic_subscription" "slack" {
  count = var.slack_webhook_url != "" ? 1 : 0

  topic_arn = aws_sns_topic.monitoring.arn
  protocol  = "https"
  endpoint  = var.slack_webhook_url
}

# ============================================================================
# IAM ROLES FOR SNS
# ============================================================================

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