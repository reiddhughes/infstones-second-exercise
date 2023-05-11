terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
}

variable "user_name" {
  type    = string
  default = "rhughes"
}

resource "aws_vpc" "main" {
  cidr_block       = "10.4.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "is-${var.user_name}-VPC-01"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.4.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "is-${var.user_name}-sn-pub-01"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.4.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "is-${var.user_name}-sn-pvt-01"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "is-${var.user_name}-igw-01"
  }
}

resource "aws_eip" "nat_gw" {
  vpc      = true
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_gw.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "is-${var.user_name}-nat-01"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "is-${var.user_name}-rt-pub-01"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "is-${var.user_name}-rt-pvt-01"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "public" {
  name        = "is-${var.user_name}-sg-pub-01"
  description = "For public subnet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "SSH from Internet"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "is-${var.user_name}-sg-pub-01"
  }
}

resource "aws_security_group" "private" {
  name        = "is-${var.user_name}-sg-pvt-01"
  description = "For private subnet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "SSH from Public Subnet"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["10.4.0.0/24"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "is-${var.user_name}-sg-pvt-01"
  }
}

resource "aws_launch_template" "private" {
  name = "is-rhughes-lt"

  iam_instance_profile {
    name = "dev-interview-iam-infra"
  }

  image_id = "ami-007855ac798b5175e"
  instance_type = "t2.micro"
  key_name = "is-${var.user_name}"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
  }

  network_interfaces {
    security_groups = [aws_security_group.private.id]
    subnet_id = aws_subnet.private.id
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "is-${var.user_name}-ec2-pvt-01"
    }
  }

  user_data = filebase64("${path.module}/userdata.sh")
}

resource "aws_instance" "pub-01" {
  ami           = "ami-007855ac798b5175e"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.public.id]
  associate_public_ip_address = true
  key_name = "is-${var.user_name}"

  tags = {
    Name = "is-${var.user_name}-ec2-pub-01"
  }
}

resource "aws_instance" "pvt-01" {
  launch_template {
    id = aws_launch_template.private.id
  }

  depends_on = [aws_route_table_association.private]
}