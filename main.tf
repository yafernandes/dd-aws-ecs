provider "aws" {
  region                  = var.region
  shared_credentials_file = "/Users/alex.fernandes/.aws/credentials"
  profile                 = "default"
}

locals {
  cluster_name = "${var.name}-cluster"
}

resource "aws_ecs_cluster" "cluster" {
  name               = local.cluster_name
  capacity_providers = ["FARGATE"]
}

resource "aws_ecs_task_definition" "app-java" {
  family                   = "app-java"
  network_mode             = "awsvpc"
  container_definitions    = templatefile("app-java.json", { dd_api_key = var.dd_api_key, dd_profiling_apikey = var.dd_profiling_apikey })
  requires_compatibilities = ["FARGATE"]
  cpu                      = "0.5 vCPU"
  memory                   = "1GB"
}

resource "aws_ecs_service" "app-java" {
  name            = "app-java"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.app-java.arn
  launch_type     = "FARGATE"
  desired_count   = 2
  network_configuration {
    subnets          = aws_subnet.main[*].id
    security_groups  = [aws_security_group.main.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.app-java.arn
    container_name   = "app-java"
    container_port   = 8080
  }

  depends_on = [
    aws_lb_listener.app-java
  ]

}
