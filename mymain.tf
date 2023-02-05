terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
# 1. Create VPC

resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "AltSCh-prod"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "Altscho_gateway" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "prod-gateway"
  }
}
# 3. Create custom Route Table

resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Altscho_gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.Altscho_gateway.id
  }

  tags = {
    Name = "AltScho-prod-route-tab"
  }
}
# 5. Associate subnet with Route Table

resource "aws_route_table_association" "AltSCh_pub_subnet1_assc" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.prod-route-table.id
}



resource "aws_route_table_association" "AltSCh_pub_subnet2_assc" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.prod-route-table.id
}
# 4. Create Subnet

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.prod-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "Altscho-pub-subnet1"
  }
}


resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.prod-vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name = "Altscho-pub-subnet2"
  }
}
# 7. Create a network interface with an IP in the subnet that was created in step 4

resource "aws_network_acl" "Altschool-network_acl" {
  vpc_id     = aws_vpc.prod-vpc.id
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}


# Create Security group for load Balanacer

resource "aws_security_group" "Altscho-load_bal_sg" {
  name        = "Altschool-load-balancer-sg"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.prod-vpc.id
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


# 6. Create security group and allow port 22, 80, 443

resource "aws_security_group" "allow_web_traffic" {
  name        = "allow_web_traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    security_groups  = [aws_security_group.Altscho-load_bal_sg.id]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    security_groups  = [aws_security_group.Altscho-load_bal_sg.id]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# Creating instance1

resource "aws_instance" "Altschool1" {
  ami               = "ami-00874d747dde814fa"
  instance_type     = "t2.micro"
  key_name          = "kings_kid"
  security_groups   = [aws_security_group.allow_web_traffic.id]
  subnet_id         = aws_subnet.subnet1.id
  availability_zone = "us-east-1a"

  provisioner "local-exec" {
    command = "echo ${self.public_ip} >>  /home/tarfa/ansible/host_inventry"
  }
  tags = {
    Name   = "Altschool-1"
    source = "terraform"
  }
}
# creating instance 2
resource "aws_instance" "Altschool2" {
  ami               = "ami-00874d747dde814fa"
  instance_type     = "t2.micro"
  key_name          = "kings_kid"
  security_groups   = [aws_security_group.allow_web_traffic.id]
  subnet_id         = aws_subnet.subnet2.id
  availability_zone = "us-east-1b"

  provisioner "local-exec" {
    command = "echo ${self.public_ip} >>  /home/tarfa/ansible/host_inventry"
  }

  tags = {
    Name   = "Altschool-2"
    source = "terraform"
  }
}
# creating instance 3
resource "aws_instance" "Altschool3" {
  ami               = "ami-00874d747dde814fa"
  instance_type     = "t2.micro"
  key_name          = "kings_kid"
  security_groups   = [aws_security_group.allow_web_traffic.id]
  subnet_id         = aws_subnet.subnet1.id
  availability_zone = "us-east-1a"

  provisioner "local-exec" {
    command = "echo ${self.public_ip} >>  /home/tarfa/ansible/host_inventry"
  }

  tags = {
    Name   = "Altschool-3"
    source = "terraform"
  }
}
# Create a file to store the IP addresses of the instances

# resource "local_file" "Ip_address" {
#   filename = "home/tarfa/ansible/host_inventry"
#   content  = <<EOT
# ${aws_instance.Altschool1.public_ip}
# ${aws_instance.Altschool2.public_ip}
# ${aws_instance.Altschool3.public_ip}
#   EOT
# }
# Create an Application Load Balancer

resource "aws_lb" "Altscho-load-balancer" {
  name               = "Altscho-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Altscho-load_bal_sg.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  #enable_cross_zone_load_balancing = true
  enable_deletion_protection = false
  depends_on                 = [aws_instance.Altschool1, aws_instance.Altschool2, aws_instance.Altschool3]
}

# Create the target group

resource "aws_lb_target_group" "Altschool-target-group" {
  name        = "Altschool-target-group"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.prod-vpc.id
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

# Create the listener

resource "aws_lb_listener" "Altschool-listener" {
  load_balancer_arn = aws_lb.Altscho-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  }
}
# Create the listener rule
resource "aws_lb_listener_rule" "Altschool-listener-rule" {
  listener_arn = aws_lb_listener.Altschool-listener.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}
# Attach the target group to the load balancer

resource "aws_lb_target_group_attachment" "Altschool-target-group-attachment1" {
  target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  target_id        = aws_instance.Altschool1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "Altschool-target-group-attachment2" {
  target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  target_id        = aws_instance.Altschool2.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "Altschool-target-group-attachment3" {
  target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  target_id        = aws_instance.Altschool3.id
  port             = 80

}

# provisioner "local-exec" {
#   command = "ansible-playbook -i host-inventory playbook.yml"
# }
