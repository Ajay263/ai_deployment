# environments/staging/terragrunt.hcl
# Staging Environment Terragrunt Configuration

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Environment-specific inputs
inputs = {
  # Environment configuration
  environment = "staging"

  # Infrastructure settings (slightly larger than dev)
  vpc_cidr    = "10.1.0.0/16"
  num_subnets = 3
  allowed_ips = ["0.0.0.0/0"] # In production, restrict this to office IPs

  # Application configuration
  applications = {
    ui = {
      ecr_repository_name = "ui"
      app_path            = "ui"
      image_version       = "1.0.1"
      app_name            = "ui"
      port                = 80
      cpu                 = 512  # Higher than dev
      memory              = 1024 # Higher than dev
      desired_count       = 2    # More instances for staging
      is_public           = true
      path_pattern        = "/*"
      lb_priority         = 20
      healthcheck_path    = "/"
      healthcheck_command = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
      secrets             = []
      envars              = []
    }
    api = {
      ecr_repository_name = "api"
      app_path            = "api"
      image_version       = "1.0.4"
      app_name            = "api"
      port                = 5000
      cpu                 = 1024 # Higher than dev
      memory              = 2048 # Higher than dev
      desired_count       = 2    # More instances for staging
      is_public           = true
      path_pattern        = "/api/*"
      lb_priority         = 10
      healthcheck_path    = "/api/healthcheck"
      healthcheck_command = ["CMD-SHELL", "curl -f http://localhost:5000/api/healthcheck || exit 1"]
      secrets = [
        {
          name      = "GROQ_API_KEY"
          valueFrom = "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:groqkey"
        }
      ]
      envars = []
    }
  }

  # Monitoring configuration (production-like but less sensitive)
  notification_emails = ["junioralexio607@gmail.com"]
  cpu_threshold       = 75 # Moderate threshold
  memory_threshold    = 80
  alb_5xx_threshold   = 5
  log_retention_days  = 14 # Moderate retention

  # Enable features
  enable_detailed_monitoring    = true
  enable_container_insights     = true
  enable_cost_anomaly_detection = true # Enabled for staging
}