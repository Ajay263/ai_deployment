# environments/prod/terragrunt.hcl
# Production Environment Terragrunt Configuration

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Environment-specific inputs
inputs = {
  # Environment configuration
  environment = "prod"
  
  # Infrastructure settings (production-grade)
  vpc_cidr    = "10.2.0.0/16"
  num_subnets = 3
  allowed_ips = ["0.0.0.0/0"]  # TODO: Restrict to office/CDN IPs in real production
  
  # Application configuration (production-scale)
  applications = {
    ui = {
      ecr_repository_name = "ui"
      app_path            = "ui"
      image_version       = "1.0.1"
      app_name            = "ui"
      port                = 80
      cpu                 = 1024   # Production resources
      memory              = 2048   # Production resources
      desired_count       = 3      # High availability
      is_public           = true
      path_pattern        = "/*"
      lb_priority         = 20
      healthcheck_path    = "/"
      healthcheck_command = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
      secrets             = []
      envars = [
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]
    }
    api = {
      ecr_repository_name = "api"
      app_path            = "api"
      image_version       = "1.0.4"
      app_name            = "api"
      port                = 5000
      cpu                 = 2048   # Production resources
      memory              = 4096   # Production resources
      desired_count       = 3      # High availability
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
      envars = [
        {
          name  = "FLASK_ENV"
          value = "production"
        },
        {
          name  = "LOG_LEVEL"
          value = "INFO"
        }
      ]
    }
  }
  
  # Monitoring configuration (production-grade)
  notification_emails = [
    "junioralexio607@gmail.com",
    "ops-team@company.com"  # Add your ops team email
  ]
  critical_notification_emails = [
    "on-call@company.com"   # Add your on-call email
  ]
  cpu_threshold              = 80   # Higher threshold for production
  memory_threshold           = 85
  alb_5xx_threshold         = 10    # Higher threshold for production
  alb_response_time_threshold = 5.0
  log_retention_days        = 30    # Longer retention for production
  
  # Enable all features for production
  enable_detailed_monitoring     = true
  enable_container_insights      = true
  enable_cost_anomaly_detection  = true
}