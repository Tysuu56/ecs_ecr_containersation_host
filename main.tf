provider "aws" {
  region = var.aws_region
}

# Step 2: Create ECR Repository
resource "aws_ecr_repository" "my_ecr" {
  name = var.ecr_repository_name
}

# Step 3: Create ECS Cluster
resource "aws_ecs_cluster" "my_ecs_cluster" {
  name = var.ecs_cluster_name
}

# Create IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = var.ecs_execution_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_execution_policy" {
  name       = "ecs_execution_policy_attachment"
  roles      = [aws_iam_role.ecs_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Step 4: Define Task Definition
resource "aws_ecs_task_definition" "my_task" {
  family                   = var.task_family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name      = var.container_name
    image     = "${aws_ecr_repository.my_ecr.repository_url}:${var.image_tag}"
    memory    = var.container_memory
    cpu       = var.container_cpu
    essential = true
    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.log_group_name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# Step 5: Create ECS Service
resource "aws_ecs_service" "my_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.my_ecs_cluster.id
  task_definition = aws_ecs_task_definition.my_task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  force_new_deployment = true

  network_configuration {
    subnets         = var.subnets
    security_groups = [aws_security_group.ecs_security_group.id]
    assign_public_ip = "true"
  }
}

# Create Security Group for ECS Task
resource "aws_security_group" "ecs_security_group" {
  vpc_id = var.vpc_id
  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Outputs
output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.my_ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.my_ecs_cluster.name
}

