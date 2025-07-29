# ECS Module Outputs

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "service_arns" {
  description = "Map of service ARNs"
  value       = { for k, v in aws_ecs_service.this : k => v.id }
}

output "service_names" {
  description = "Map of service names"
  value       = { for k, v in aws_ecs_service.this : k => v.name }
}

output "task_definition_arns" {
  description = "Map of task definition ARNs"
  value       = { for k, v in aws_ecs_task_definition.this : k => v.arn }
}

output "target_group_arns" {
  description = "Map of target group ARNs"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn }
}

output "target_group_arn_suffixes" {
  description = "Map of target group ARN suffixes"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn_suffix }
}