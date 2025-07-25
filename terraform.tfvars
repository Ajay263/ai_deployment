# terraform.tfvars.example
# Copy this file to terraform.tfvars and update the values

# Monitoring configuration
notification_emails = [
  "junioralexio607@gmail.com"
 
]

# Monitoring thresholds
cpu_threshold = 80
memory_threshold = 80
error_threshold = 5

# Log retention (days)
log_retention_days = 14

# Environment
environment = "dev"  # or "prod", "staging"

# AWS Region (if different from provider default)
aws_region = "us-east-1"