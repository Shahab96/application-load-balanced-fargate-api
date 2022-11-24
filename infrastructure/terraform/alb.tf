resource "aws_lb" "this" {
  name               = local.project_prefix
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this["alb"].id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]
  enable_http2       = true

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "this" {
  name             = local.project_prefix
  protocol         = "HTTP"
  port             = var.container_port
  vpc_id           = aws_vpc.this.id
  target_type      = "ip"

  health_check {
    healthy_threshold   = 3
    interval            = 30
    protocol            = "HTTP"
    matcher             = 200
    timeout             = 3
    path                = "/"
    unhealthy_threshold = 2
    enabled             = true
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.id
  protocol          = "HTTPS"
  port              = 443
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = module.acm.acm_certificate_arn
  
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Hello, world! From ALB"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = aws_lb_listener.this.arn

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    host_header {
      values = [aws_route53_zone.this.name]
    }
  }
}

resource "aws_appautoscaling_target" "this" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "this" {
  for_each = {
    memory = "ECSServiceAverageMemoryUtilization"
    cpu    = "ECSServiceAverageCPUUtilization"
  }

  name               = "${local.project_prefix}-${each.key}-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = each.value
    }

    target_value = 80
  }
}