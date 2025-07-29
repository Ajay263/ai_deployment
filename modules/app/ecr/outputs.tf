# ECR Module Outputs

output "repository_urls" {
  description = "Map of ECR repository URLs"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of ECR repository ARNs"
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}

output "repository_registry_ids" {
  description = "Map of ECR repository registry IDs"
  value       = { for k, v in aws_ecr_repository.this : k => v.registry_id }
}

output "repositories" {
  description = "Complete ECR repository information"
  value = {
    for k, v in aws_ecr_repository.this : k => {
      url         = v.repository_url
      arn         = v.arn
      registry_id = v.registry_id
      name        = v.name
    }
  }
}