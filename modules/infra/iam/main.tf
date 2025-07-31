# IAM Module - Extracted from original infra module

# ECS Task Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.cluster_name}-ecsExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# Custom policy for Secrets Manager access
resource "aws_iam_policy" "ecs_secrets_policy" {
  name        = "${var.cluster_name}-ecs-secrets-policy"
  description = "Allow ECS tasks to retrieve all secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

# Attach custom secrets policy to execution role
resource "aws_iam_role_policy_attachment" "ecs_secrets_policy_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}

# Attach AWS managed ECS execution policy
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}