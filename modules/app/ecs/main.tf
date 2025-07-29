# ECS Module - Extracted and enhanced from original modules/app

# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(var.tags, {
    Name = var.cluster_name
    Type = "ECS Cluster"
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "this" {
  for_each = var.applications

  family                   = "${each.key}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name        = each.key
      image       = "${var.ecr_repositories[each.key].url}:${each.value.image_version}"
      cpu         = each.value.cpu
      memory      = each.value.memory
      essential   = true
      environment = each.value.envars
      secrets     = each.value.secrets
      
      portMappings = [
        {
          containerPort = each.value.port
          hostPort      = each.value.port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.cluster_name}/${each.key}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = each.value.healthcheck_command != null ? {
        command     = each.value.healthcheck_command
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      } : null
    }
  ])

  tags = merge(var.tags, {
    Application = each.key
  })
}

# ECS Service
resource "aws_ecs_service" "this" {
  for_each = var.applications

  name            = "${each.key}-service"
  cluster         = aws_ecs_cluster.this.arn
  task_definition = aws_ecs_task_definition.this[each.key].arn
  launch_type     = "FARGATE"
  desired_count   = each.value.desired_count

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.app_security_group_id]
    assign_public_ip = each.value.is_public
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this[each.key].arn
    container_name   = each.key
    container_port   = each.value.port
  }

  depends_on = [aws_lb_target_group.this]

  tags = merge(var.tags, {
    Application = each.key
  })
}

# Target Groups
resource "aws_lb_target_group" "this" {
  for_each = var.applications

  name                 = "${each.key}-tg"
  port                 = each.value.port
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = each.value.healthcheck_path
    matcher             = "200"
    protocol            = "HTTP"
  }

  tags = merge(var.tags, {
    Application = each.key
  })
}

# ALB Listener Rules
resource "aws_lb_listener_rule" "this" {
  for_each = var.applications

  listener_arn = var.alb_listener_arn
  priority     = each.value.lb_priority

  condition {
    path_pattern {
      values = [each.value.path_pattern]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  tags = merge(var.tags, {
    Application = each.key
  })
}