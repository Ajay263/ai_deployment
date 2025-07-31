# Development Environment Terragrunt Configuration

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Environment-specific inputs
inputs = {
  # Environment configuration
  environment = "dev"

  # Infrastructure settings
  vpc_cidr    = "10.0.0.0/16"
  num_subnets = 3
  allowed_ips = ["0.0.0.0/0"]

  # Application configuration
  applications = {
    ui = {
      ecr_repository_name = "ui"
      app_path            = "ui"
      image_version       = "1.0.1"
      app_name            = "ui"
      port                = 80
      cpu                 = 256
      memory              = 512
      desired_count       = 1
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
      cpu                 = 512
      memory              = 1024
      desired_count       = 1 # Lower for dev
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

  # Monitoring configuration (more sensitive for dev)
  notification_emails = ["junioralexio607@gmail.com"]
  cpu_threshold       = 70 # Lower threshold for early detection
  memory_threshold    = 75
  alb_5xx_threshold   = 2
  log_retention_days  = 7 # Shorter retention for cost

  # Enable features
  enable_detailed_monitoring    = true
  enable_container_insights     = true
  enable_cost_anomaly_detection = false # Disabled for dev
}