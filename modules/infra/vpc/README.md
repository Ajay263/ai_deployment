# VPC Module

This module creates a VPC with public subnets across multiple availability zones.

## Resources Created

- VPC with DNS support enabled
- Internet Gateway
- Public subnets (configurable number)
- Route table with internet gateway route
- Route table associations

## Usage

```hcl
module "vpc" {
  source = "../modules/infra/vpc"
  
  vpc_cidr      = "10.0.0.0/16"
  num_subnets   = 3
  cluster_name  = "my-cluster"
  tags         = local.common_tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_cidr | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| num_subnets | Number of public subnets to create | `number` | `3` | no |
| cluster_name | Name of the ECS cluster | `string` | n/a | yes |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr_block | CIDR block of the VPC |
| public_subnet_ids | List of public subnet IDs |
| internet_gateway_id | ID of the Internet Gateway |