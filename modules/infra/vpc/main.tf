# VPC Module - Extracted from original infra module
# Creates VPC, subnets, IGW, and routing

locals {
  azs = data.aws_availability_zones.available.names
}

data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-igw"
  })
}

# Route Table
resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-rt"
  })
}

# Route
resource "aws_route" "this" {
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Subnets.
resource "aws_subnet" "this" {
  for_each = { for i in range(var.num_subnets) : "public${i}" => i }
  
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(aws_vpc.this.cidr_block, 8, each.value)
  availability_zone       = local.azs[each.value % length(local.azs)]
  map_public_ip_on_launch = true
  
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-${each.key}"
    Type = "Public"
  })
}

# Route Table Associations
resource "aws_route_table_association" "this" {
  for_each = aws_subnet.this
  
  subnet_id      = each.value.id
  route_table_id = aws_route_table.this.id
}