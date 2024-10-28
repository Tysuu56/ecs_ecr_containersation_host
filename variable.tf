variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "my-ecr-repo"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "my-ecs-cluster"
}

variable "ecs_execution_role_name" {
  description = "Name of the ECS execution role"
  type        = string
  default     = "ecs_execution_role"
}

variable "task_family" {
  description = "Family name for the ECS task"
  type        = string
  default     = "my-task-family"
}

variable "task_cpu" {
  description = "CPU units for the ECS task"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory for the ECS task"
  type        = string
  default     = "512"
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "my-container"
}

variable "image_tag" {
  description = "Tag of the image to use from ECR"
  type        = string
  default     = "latest"
}

variable "container_memory" {
  description = "Memory allocation for the container"
  type        = number
  default     = 512
}

variable "container_cpu" {
  description = "CPU units for the container"
  type        = number
  default     = 256
}

variable "container_port" {
  description = "Port for the container"
  type        = number
  default     = 3000
}

variable "log_group_name" {
  description = "CloudWatch log group name for the container"
  type        = string
  default     = "/ecs/my-container-logs"
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "my-service"
}

variable "desired_count" {
  description = "Desired count of ECS service instances"
  type        = number
  default     = 1
}

variable "subnets" {
  description = "List of subnet IDs for the ECS service"
  type        = list(string)
  default     = ["subnet-0133464e162b2af3f", "subnet-0d129f41d7b92f0b8"]
}

variable "vpc_id" {
  description = "VPC ID where the ECS service and security group are created"
  type        = string
  default     = "vpc-0386f1d86a871398c"
}
