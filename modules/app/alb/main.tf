# ALB Module - Extracted from original infra module

# Application Load Balancer
resource "aws_lb" "this" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-alb"
    Type = "Application Load Balancer"
  })
}

# ALB Listener
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Service is running, but no specific application matched your request"
      status_code  = "503"
    }
  }
  
  tags = var.tags
}