# Cost Security Module Variables
# File: modules/monitoring/cost-security/variables.tf

variable "cluster_name" {
  description = "Name of the ECS cluster (used for resource naming)"
  type        = string
}

variable "notification_emails" {
  description = "List of email addresses to receive cost and security alerts"
  type        = list(string)
  default     = []
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}