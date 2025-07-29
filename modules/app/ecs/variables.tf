# ECS Module Variables

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "applications" {
  description = "Map of applications to deploy"
  type = map(object({
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
    image_version       = string
  }))
}

variable "ecr_repositories" {
  description = "Map of ECR repository information"
  type = map(object({
    url = string
    arn = string
  }))
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
  default     = null
}

variable "app_security_group_id" {
  description = "Security group ID for the application"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
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