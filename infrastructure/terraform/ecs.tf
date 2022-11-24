data "aws_ecr_image" "this" {
  repository_name = aws_ecr_repository.this.name
  image_tag       = "latest"
}

resource "aws_security_group" "this" {
  name   = local.project_prefix
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "ingress" {
  cidr_blocks       = [aws_vpc.this.cidr_block]
  from_port         = 80
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  type              = "ingress"
}

resource "aws_security_group_rule" "egress" {
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  type              = "egress"
  security_group_id = aws_security_group.this.id
}

resource "aws_ecs_cluster" "this" {
  name = local.project_prefix
}

resource "aws_ecs_service" "this" {
  depends_on = [
    aws_vpc_endpoint.this
  ]

  name    = local.project_prefix
  cluster = aws_ecs_cluster.this.arn

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0
  desired_count                      = 1
  launch_type                        = "FARGATE"

  task_definition = aws_ecs_task_definition.this.arn

  network_configuration {
    assign_public_ip = false
    subnets          = [aws_subnet.this[1].id]
    security_groups  = [aws_security_group.this.id]
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
        command = ["CMD-SHELL", "curl -f http://localhost:3000/ || exit 1"]
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = data.aws_region.this.name
          awslogs-stream-prefix = local.project_prefix
        }
      }
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    },
  ])

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}