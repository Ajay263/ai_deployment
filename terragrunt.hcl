# Root Terragrunt Configuration
# This file contains shared configuration for all environments

locals {
  # Common variables across all environments.
  project_name = "mtc-app"
  aws_region   = "us-east-1"
  
  # Common tags
  common_tags = {
    Project     = local.project_name
    ManagedBy   = "terragrunt"
    Repository  = "terraform-ecs-project"
  }
}

# Generate AWS provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }
}
EOF
}

# Configure remote state
remote_state {
  backend = "s3"
  config = {
    bucket         = "ai-deployemnts-ajay"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}

# Input validation
inputs = {
  aws_region   = local.aws_region
  project_name = local.project_name
  common_tags  = local.common_tags
}