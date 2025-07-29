# Development Environment

This directory contains the Terraform configuration for the **development** environment of the MTC ECS application.

## Overview

The development environment is configured with:
- **Lower resource allocation** for cost optimization
- **More sensitive monitoring thresholds** for early issue detection
- **Shorter log retention** (7 days) to reduce costs
- **Single instance** of each service to minimize resource usage

## Architecture

### Infrastructure Components
- **VPC**: 10.0.0.0/16 with 3 public subnets across AZs
- **ECS Cluster**: Fargate-based with Container Insights enabled
- **Application Load Balancer**: Internet-facing with security groups
- **ECR Repositories**: For UI and API container images

### Applications
- **UI Service**: Nginx-based frontend (port 80, 256 CPU, 512 MB memory)
- **API Service**: Flask-based backend (port 5000, 512 CPU, 1024 MB memory)

### Monitoring
- **CloudWatch**: Comprehensive logging and metrics
- **SNS**: Email notifications for alerts
- **Alarms**: CPU (>70%), Memory (>75%), ALB 5xx errors (>2)

## Usage

### Deploy the environment
```bash
cd environments/dev
terragrunt apply
```

### View plan
```bash
terragrunt plan
```

### Destroy environment
```bash
terragrunt destroy
```

### Access logs
```bash
terragrunt output monitoring_dashboard_url
```

## Configuration

### Key Variables
- `cpu_threshold`: 70% (lower than prod for early detection)
- `memory_threshold`: 75%
- `alb_5xx_threshold`: 2 errors per 5 minutes
- `log_retention_days`: 7 days
- `desired_count`: 1 instance per service

### Secrets
- GROQ API key is stored in AWS Secrets Manager as `groqkey`

## Outputs

After deployment, you can access:
- **Application URL**: `terragrunt output alb_dns_name`
- **Monitoring Dashboard**: `terragrunt output monitoring_dashboard_url`
- **Service Information**: `terragrunt output application_services`

## Development Guidelines

1. **Cost Optimization**: Resources are sized for development workloads
2. **Monitoring**: More sensitive thresholds to catch issues early
3. **Logs**: Short retention period (7 days) for cost control
4. **Scaling**: Single instance deployment for cost efficiency

## Troubleshooting

### Common Issues
1. **ECS Tasks not starting**: Check CloudWatch logs in `/ecs/mtc-app-dev/`
2. **ALB health checks failing**: Verify application is listening on correct port
3. **Docker build failures**: Check ECR permissions and Docker configuration

### Useful Commands
```bash
# View ECS service status
aws ecs describe-services --cluster mtc-app-dev --services ui-service api-service

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# View recent logs
aws logs tail /ecs/mtc-app-dev/api --follow
```