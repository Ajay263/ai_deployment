# VPC Module Variables

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "num_subnets" {
  description = "Number of public subnets to create"
  type        = number
  default     = 3
}

variable "cluster_name" {
  description = "Name of the ECS cluster (used for resource naming)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}