# environments/prod/variables.tf
# Production Environment Variables

# ============================================================================
# INHERITED FROM ROOT
# ============================================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "common_tags" {
  description = "Common tags from root configuration"
  type        = map(string)
}

# ============================================================================
# ENVIRONMENT SPECIFIC
# ============================================================================

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

# ============================================================================
# INFRASTRUCTURE CONFIGURATION
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "num_subnets" {
  description = "Number of public subnets to create"
  type        = number
  default     = 3
}

variable "allowed_ips" {
  description = "Set of IP addresses allowed to access the ALB"
  type        = set(string)
  default     = ["0.0.0.0/0"]
  validation {
    condition     = length(var.allowed_ips) > 0
    error_message = "At least one IP address must be allowed."
  }
}

# ============================================================================
# APPLICATION CONFIGURATION
# ============================================================================

variable "applications" {
  description = "Map of applications to deploy"
  type = map(object({
    ecr_repository_name = string
    app_path            = string
    image_version       = string
    app_name            = string
    port                = number
    cpu                 = number
    memory              = number
    desired_count       = number
    is_public           = bool
    path_pattern        = string
    lb_priority         = number
    healthcheck_path    = string
    healthcheck_command = list(string)
    secrets             = list(map(string))
    envars              = list(map(string))
  }))
  validation {
    condition = alltrue([
      for app in values(var.applications) : app.desired_count >= 2
    ])
    error_message = "Production applications must have at least 2 instances for high availability."
  }
}

# ============================================================================
# MONITORING CONFIGURATION
# ============================================================================

variable "notification_emails" {
  description = "List of email addresses to receive monitoring alerts"
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.notification_emails) > 0
    error_message = "At least one notification email must be provided for production."
  }
}

variable "critical_notification_emails" {
  description = "Email addresses for critical alerts (on-call team)"
  type        = list(string)
  default     = []
}

variable "warning_notification_emails" {
  description = "Email addresses for warning alerts"
  type        = list(string)
  default     = []
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "pagerduty_integration_key" {
  description = "PagerDuty integration key for critical alerts"
  type        = string
  default     = ""
  sensitive   = true
}

# ============================================================================
# MONITORING THRESHOLDS (PRODUCTION TUNED)
# ============================================================================

variable "cpu_threshold" {
  description = "CPU utilization threshold for alarms (percentage)"
  type        = number
  default     = 80
  validation {
    condition     = var.cpu_threshold >= 50 && var.cpu_threshold <= 95
    error_message = "CPU threshold must be between 50 and 95 percent."
  }
}

variable "memory_threshold" {
  description = "Memory utilization threshold for alarms (percentage)"
  type        = number
  default     = 85
  validation {
    condition     = var.memory_threshold >= 50 && var.memory_threshold <= 95
    error_message = "Memory threshold must be between 50 and 95 percent."
  }
}

variable "task_count_threshold" {
  description = "Minimum number of running tasks before alarm"
  type        = number
  default     = 2
  validation {
    condition     = var.task_count_threshold >= 1
    error_message = "Task count threshold must be at least 1."
  }
}

variable "alb_response_time_threshold" {
  description = "ALB response time threshold in seconds"
  type        = number
  default     = 5.0
  validation {
    condition     = var.alb_response_time_threshold > 0
    error_message = "ALB response time threshold must be positive."
  }
}

variable "alb_5xx_threshold" {
  description = "ALB 5xx error count threshold per 5 minutes"
  type        = number
  default     = 10
}

variable "alb_4xx_threshold" {
  description = "ALB 4xx error count threshold per 5 minutes"
  type        = number
  default     = 100
}

variable "error_threshold" {
  description = "Application error count threshold per 5 minutes"
  type        = number
  default     = 10
}

variable "flask_5xx_threshold" {
  description = "Flask API 5xx error count threshold per 5 minutes"
  type        = number
  default     = 10
}

variable "warning_threshold" {
  description = "Application warning count threshold per 5 minutes"
  type        = number
  default     = 20
}

# ============================================================================
# FEATURE FLAGS
# ============================================================================

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
  validation {
    condition     = var.log_retention_days >= 14
    error_message = "Log retention must be at least 14 days for production."
  }
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = true
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "enable_cost_anomaly_detection" {
  description = "Enable AWS Cost Anomaly Detection"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable backup for production resources"
  type        = bool
  default     = true
}

variable "enable_multi_az" {
  description = "Enable multi-AZ deployment"
  type        = bool
  default     = true
}