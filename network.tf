data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "aws_availability_zones" "available" {
  state                = "available"
  blacklisted_zone_ids = ["us-west-2d"]
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"

  tags = {
    Name    = local.cluster_name
    Creator = "alex.fernandes"
  }
}

resource "aws_subnet" "main" {
  count                   = var.num_of_subnets
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  map_public_ip_on_launch = true
}

resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id
  name   = "main_security_group"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = local.cluster_name
    Creator = "alex.fernandes"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "main" {
  count          = var.num_of_subnets
  subnet_id      = aws_subnet.main[count.index].id
  route_table_id = aws_route_table.main.id
}

resource "aws_lb" "main" {
  name               = "ecs-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.main.id]
  subnets            = aws_subnet.main[*].id
}

resource "aws_lb_listener" "app-java" {
  load_balancer_arn = aws_lb.main.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app-java.arn
  }
}

resource "aws_lb_target_group" "app-java" {
  name        = "app-java"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
}
