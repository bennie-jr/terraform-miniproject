provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "instance_1" {
  ami             = "ami-011899242bb902164"
  instance_type   = "t2.micro"
  key_name        = "mp-keys"
  security_groups = [aws_security_group.mp-instances-sg.id]
  subnet_id       = aws_subnet.mp-public-subnet-1.id
}

resource "aws_instance" "instance_2" {
  ami             = "ami-011899242bb902164"
  instance_type   = "t2.micro"
  key_name        = "mp-keys"
  security_groups = [aws_security_group.mp-instances-sg.id]
  subnet_id       = aws_subnet.mp-public-subnet-2.id
}

resource "aws_instance" "instance_3" {
  ami             = "ami-011899242bb902164"
  instance_type   = "t2.micro"
  key_name        = "mp-keys"
  security_groups = [aws_security_group.mp-instances-sg.id]
  subnet_id       = aws_subnet.mp-public-subnet-1.id
}

resource "aws_vpc" "miniproject_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "miniproject_vpc"
  }
}

resource "aws_subnet" "mp-public-subnet-1" {
  vpc_id                  = aws_vpc.miniproject_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "mp-public-subnet-1"
  }
}

resource "aws_subnet" "mp-public-subnet-2" {
  vpc_id                  = aws_vpc.miniproject_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name = "mp-public-subnet-2"
  }
}
resource "aws_internet_gateway" "miniproject_igw" {
  vpc_id = aws_vpc.miniproject_vpc.id

  tags = {
    Name = "miniproject_igw"
  }
}

resource "aws_route_table" "miniproject_public_rt" {
  vpc_id = aws_vpc.miniproject_vpc.id

  route {
    cidr_block  = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.miniproject_igw.id
  }

  tags = {
    Name = "miniproject_public_rt"
  }
}

resource "aws_route_table_association" "mp-public-subnet-1-association" {
  subnet_id      = aws_subnet.mp-public-subnet-1.id
  route_table_id = aws_route_table.miniproject_public_rt.id
}

resource "aws_route_table_association" "mp-public-subnet-2-association" {
  subnet_id      = aws_subnet.mp-public-subnet-2.id
  route_table_id = aws_route_table.miniproject_public_rt.id
}

resource "aws_network_acl" "miniproject_network_acl" {
  vpc_id     = aws_vpc.miniproject_vpc.id
  subnet_ids = [aws_subnet.mp-public-subnet-1.id, aws_subnet.mp-public-subnet-2.id]

  ingress {
    rule_no     = 100
    protocol    = "-1"
    action      = "allow"
    cidr_block  = "0.0.0.0/0"
    from_port   = 0
    to_port     = 0
  }

  egress {
    rule_no     = 100
    protocol    = "-1"
    action      = "allow"
    cidr_block  = "0.0.0.0/0"
    from_port   = 0
    to_port     = 0
  }
}
resource "aws_security_group" "mp-instances-sg" {
  name   = "allow_http_https_ssh"
  vpc_id = aws_vpc.miniproject_vpc.id

  ingress {
    description = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.mp-lb-sg.id]
  }

  ingress {
    description     = "HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.mp-lb-sg.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mp-instances-sg"
  }
}

resource "aws_security_group" "mp-lb-sg" {
  name   = "mp-lb-sg"
  vpc_id = aws_vpc.miniproject_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.mp-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.miniproject-tg.arn
  }
}


resource "aws_lb_target_group" "miniproject-tg" {
  name       = "miniproject-tg"
  target_type = "instance"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = aws_vpc.miniproject_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "mp-tg-attachment-1" {
  target_group_arn = aws_lb_target_group.miniproject-tg.arn
  target_id        = aws_instance.instance_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "mp-tg-attachment-2" {
  target_group_arn = aws_lb_target_group.miniproject-tg.arn
  target_id        = aws_instance.instance_2.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "mp-tg-attachment-3" {
  target_group_arn = aws_lb_target_group.miniproject-tg.arn
  target_id        = aws_instance.instance_3.id
  port             = 80
}


resource "aws_lb_listener_rule" "mp-listener-rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  condition {
    path_pattern {
      values = ["/"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.miniproject-tg.arn
  }
}

resource "aws_lb" "mp-load-balancer" {
  name                       = "mp-load-balancer"
  load_balancer_type         = "application"
  subnets                    = [aws_subnet.mp-public-subnet-1.id, aws_subnet.mp-public-subnet-2.id]
  security_groups            = [aws_security_group.mp-lb-sg.id]
  enable_deletion_protection = false

}

resource "aws_route53_zone" "primary" {
  name = "bennielj.me"
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "terraform-test.bennielj.me"
  type    = "A"

  alias {
    name                    = aws_lb.mp-load-balancer.dns_name
    zone_id                 = aws_lb.mp-load-balancer.zone_id
    evaluate_target_health  = true
  }
}
resource "local_file" "ip_address" {
  filename = "/home/vagrant/miniproject-terraform/host-inventory"
  content  = <<EOT
        [all]
        ${aws_instance.instance_1.public_ip}
        ${aws_instance.instance_2.public_ip}
        ${aws_instance.instance_3.public_ip}
        EOT
}
