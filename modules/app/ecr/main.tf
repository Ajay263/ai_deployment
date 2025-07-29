# ECR Module - Extracted from original app module

# Data source for ECR authorization token
data "aws_ecr_authorization_token" "this" {}

# ECR Repositories
resource "aws_ecr_repository" "this" {
  for_each = var.applications

  name         = each.value.ecr_repository_name
  force_delete = var.force_delete

  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = merge(var.tags, {
    Name        = each.value.ecr_repository_name
    Application = each.key
  })
}

# ECR Repository Policies (optional)
resource "aws_ecr_repository_policy" "this" {
  for_each = var.repository_policies

  repository = aws_ecr_repository.this[each.key].name
  policy     = each.value
}

# Docker operations - Login
resource "terraform_data" "login" {
  for_each = var.applications
  
  provisioner "local-exec" {
    command = <<EOT
        docker login ${aws_ecr_repository.this[each.key].repository_url} \
        --username ${data.aws_ecr_authorization_token.this.user_name} \
        --password ${data.aws_ecr_authorization_token.this.password}
        EOT
  }
}

# Docker operations - Build
resource "terraform_data" "build" {
  for_each = var.applications
  
  triggers_replace = [
    each.value.image_version
  ]
  depends_on = [terraform_data.login]
  
  provisioner "local-exec" {
    command = <<EOT
        docker build -t ${aws_ecr_repository.this[each.key].repository_url} ${var.docker_build_path}/${each.value.app_path}
        EOT
  }
}

# Docker operations - Push
resource "terraform_data" "push" {
  for_each = var.applications
  
  triggers_replace = [
    each.value.image_version
  ]
  depends_on = [terraform_data.login, terraform_data.build]
  
  provisioner "local-exec" {
    command = <<EOT
        docker image tag ${aws_ecr_repository.this[each.key].repository_url} ${aws_ecr_repository.this[each.key].repository_url}:${each.value.image_version}
        docker image tag ${aws_ecr_repository.this[each.key].repository_url} ${aws_ecr_repository.this[each.key].repository_url}:latest
        docker image push ${aws_ecr_repository.this[each.key].repository_url}:${each.value.image_version}
        docker image push ${aws_ecr_repository.this[each.key].repository_url}:latest
        EOT
  }
}