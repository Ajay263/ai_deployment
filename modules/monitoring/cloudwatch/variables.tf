# CloudWatch Module Variables

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
}

variable "applications" {
  description = "Map of applications to monitor"
  type        = map(object({
    name = string
  }))
}

variable "load_balancer_arn_suffix" {
  description = "ARN suffix of the load balancer"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}