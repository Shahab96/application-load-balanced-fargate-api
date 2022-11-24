data "aws_ecr_image" "this" {
  depends_on = [
    null_resource.this
  ]

  repository_name = aws_ecr_repository.this.name
  image_tag       = "latest"
}

resource "aws_ecs_cluster" "this" {
  name = local.project_prefix
}

resource "aws_ecs_service" "this" {
  name    = local.project_prefix
  cluster = aws_ecs_cluster.this.arn

  deployment_maximum_percent         = 400
  deployment_minimum_healthy_percent = 0
  desired_count                      = 1
  launch_type                        = "FARGATE"

  task_definition = aws_ecs_task_definition.this.arn

  network_configuration {
    assign_public_ip = false
    subnets          = [for subnet in aws_subnet.private : subnet.id]
    security_groups  = [aws_security_group.this["service"].id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = local.project_prefix
    container_port   = var.container_port
  }
}

data "aws_iam_role" "this" {
  name = "ecsTaskExecutionRole"
}

resource "aws_cloudwatch_log_group" "this" {
  name = local.project_prefix
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.project_prefix
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.this.arn
  container_definitions = jsonencode([
    {
      name  = local.project_prefix
      image = "${aws_ecr_repository.this.repository_url}:${data.aws_ecr_image.this.image_tag}"
      healthCheck = {
        command  = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/ || exit 1"]
        interval = 30
        retries  = 3
        timeout  = 5
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = data.aws_region.this.name
          awslogs-stream-prefix = local.project_prefix
        }
      }
      cpu         = 256
      memory      = 512
      essential   = true
      environment = []
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
    },
  ])

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}