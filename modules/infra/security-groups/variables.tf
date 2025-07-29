# Security Groups Module Variables

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster (used for resource naming)"
  type        = string
}

variable "allowed_ips" {
  description = "Set of IP addresses allowed to access the ALB"
  type        = set(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}