################################################################
# use aws default VPC
data "aws_vpc" "default_vpc" {
  default = true
}
# use aws default subnet
data "aws_subnet" "default_subnet" {
  vpc_id = data.aws_vpc.default_vpc.id
  availability_zone = "us-east-1a"
}
# use aws default subnet
data "aws_subnet" "default_subnet2" {
  vpc_id = data.aws_vpc.default_vpc.id
  availability_zone = "us-east-1b"
}
output "default_subnet_ids" {
  value = data.aws_subnet.default_subnet.id
}
# create a security group for the instances
resource "aws_security_group" "instances" {
  name = "instance-security-group"
}
# defining the trafic type that the security group will allow
resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instances.id

  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
# creating the first ec2 instance
resource "aws_instance" "instance_1" {
  ami             = "ami-011899242bb902164" # Ubuntu 20.04 LTS // us-east-1
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instances.name]
  # availability_zone = "us-east-1b"
  user_data       = <<-EOF
              #!/bin/bash
              echo "Hello, Welcome to My Simple Web Page" > index.html
              python3 -m http.server 8080 &
              EOF
}
# creating the second ec2 instance
resource "aws_instance" "instance_2" {
  ami             = "ami-011899242bb902164" # Ubuntu 20.04 LTS // us-east-1
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instances.name]
  # availability_zone = "us-east-1a"
  user_data       = <<-EOF
              #!/bin/bashb
              echo "This is a basic example of a web page deployed on aws EC2" > index.html
              python3 -m http.server 8080 &
              EOF
}
# creating a load balancer to accep hpp traffic
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn

  port = 80

  protocol = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}
# defining target group for the load balancer
resource "aws_lb_target_group" "instances" {
  name     = "example-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
# attaching the instances to the lb target group
resource "aws_lb_target_group_attachment" "instance_1" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.instance_1.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "instance_2" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.instance_2.id
  port             = 8080
}
# defining a listening rule i.e the path
resource "aws_lb_listener_rule" "instances" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instances.arn
  }
}

resource "aws_security_group" "alb" {
  name = "alb-security-group"
}

# setting inboun and outbound traffic rule for the load balance
resource "aws_security_group_rule" "allow_alb_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

}

resource "aws_security_group_rule" "allow_alb_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

}
# creating the load balancer
resource "aws_lb" "load_balancer" {
  name               = "web-app-lb"
  load_balancer_type = "application"
  subnets            = [data.aws_subnet.default_subnet.id, data.aws_subnet.default_subnet2.id]
  security_groups    = [aws_security_group.alb.id]
}