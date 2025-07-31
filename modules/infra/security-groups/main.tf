# Security Groups Module - Extracted from original sg.tf

# ALB Security Group
resource "aws_security_group" "alb" {
  name_prefix = "${var.cluster_name}-alb-"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-alb-sg"
    Type = "ALB"
  })
}

# ALB Ingress Rules - Allow traffic from allowed IPs
resource "aws_vpc_security_group_ingress_rule" "alb" {
  for_each = var.allowed_ips

  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80

  tags = merge(var.tags, {
    Name = "allow-http-from-${replace(each.value, "/", "-")}"
  })
}

# ALB Egress Rule - Allow traffic to application security group
resource "aws_vpc_security_group_egress_rule" "alb" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "-1"

  tags = merge(var.tags, {
    Name = "allow-all-to-app"
  })
}

# Application Security Group
resource "aws_security_group" "app" {
  name_prefix = "${var.cluster_name}-app-"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-app-sg"
    Type = "Application"
  })
}

# Application Ingress Rule - Allow traffic from ALB
resource "aws_vpc_security_group_ingress_rule" "app" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "-1"

  tags = merge(var.tags, {
    Name = "allow-all-from-alb"
  })
}

# Application Egress Rule - Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "app" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = merge(var.tags, {
    Name = "allow-all-outbound"
  })
}