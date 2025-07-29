# IAM Module Outputs

output "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "ecs_execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = aws_iam_role.ecs_execution_role.name
}

output "ecs_secrets_policy_arn" {
  description = "ARN of the ECS secrets policy"
  value       = aws_iam_policy.ecs_secrets_policy.arn
}