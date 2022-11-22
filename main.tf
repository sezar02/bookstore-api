terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.40.0"
    }
  }
}


provider "aws" {
  region  = "us-east-1"
}

data "aws_ami" "amazon-linux-2" {
  owners = ["amazon"]
  most_recent = true
  filter {
    name = "name"
    values = ["amzn2-ami-hvm*"]
  }
}
variable "secgr-dynamic-ports" {
  default = [22,80,443]
}

variable "instance-type" {
  default = "t2.micro"
  sensitive = true
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  dynamic "ingress" {
    for_each = var.secgr-dynamic-ports
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

  egress {
    description = "Outbound Allowed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "tf-ec2" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = var.instance-type
  key_name = "N.VirginiaKey"
  vpc_security_group_ids = [ aws_security_group.allow_ssh.id ]
  user_data = filebase64("user-data.sh")
      tags = {
      Name = "Web Server of Bookstore"
  }
}  
output "myec2-public-ip" {
  value = aws_instance.tf-ec2.public_ip
}