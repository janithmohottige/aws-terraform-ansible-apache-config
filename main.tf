terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]  	
  # region     = "us-east-1"
  # access_key = "<YOUR-AWS-ACCESS-KEY>"
  # secret_key = "<YOUR-AWS-SECRET-KEY>"	
}

# Create VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "production-vpc"
  }
}
# Create Internet Gateway
resource "aws_internet_gateway" "prod-gw" {
  vpc_id = aws_vpc.prod-vpc.id
  tags = {
    "Name" = "production-gw"
  }
}
# Create a Custom Route Table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod-gw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.prod-gw.id
  }
}
# Create a Subnet
resource "aws_subnet" "prod-subnet" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    "Name" = "production-subnet"
  }
}
# Associate a subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.prod-subnet.id
  route_table_id = aws_route_table.prod-route-table.id
}
# Create Security group to allow port 22,80,443
resource "aws_security_group" "prod-security-group" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
  ingress {
    description      = "ICMP"
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
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
# Create a network interface with an IP in the subnet 
resource "aws_network_interface" "nic" {
  subnet_id       = aws_subnet.prod-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.prod-security-group.id]

}
# Assign an elastic IP to the network interface
resource "aws_eip" "prod-eip" {
  vpc = true
  instance = aws_instance.prod-server.id
  network_interface = aws_network_interface.nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.prod-gw]
}
# Create ubuntu server and install apache2
resource "aws_instance" "prod-server" {
    ami = "ami-0aa7d40eeae50c9a9"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "access-key"
    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.nic.id
    }
    # user_data = <<-EOF
        # #!/bin/bash
        # sudo apt update -y
        # sudo apt install apache2 -y
        # sudo systemct1 start apache2
        # sudo bash -c "Echo your first web server > /var/www/html/index.html"
        # EOF
    tags = {
        Name = "production-server"
    }

}
output "prod-ip" {
	value = aws_instance.prod-server.public_ip
}

output "dest-ip" {
	value = aws_instance.dest-server.public_ip
}

# Create VPC
resource "aws_vpc" "dest-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    "Name" = "destination-vpc"
  }
}
# Create Internet Gateway
resource "aws_internet_gateway" "dest-gw" {
  vpc_id = aws_vpc.dest-vpc.id
  tags = {
    "Name" = "destination-gw"
  }
}
# Create a Custom Route Table
resource "aws_route_table" "dest-route-table" {
  vpc_id = aws_vpc.dest-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dest-gw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.dest-gw.id
  }
}
# Create a Subnet
resource "aws_subnet" "dest-subnet" {
  vpc_id = aws_vpc.dest-vpc.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "us-east-1b"
  tags = {
    "Name" = "destination-subnet"
  }
}
# Associate a subnet with Route Table
resource "aws_route_table_association" "b" {
  subnet_id = aws_subnet.dest-subnet.id
  route_table_id = aws_route_table.dest-route-table.id
}
# Create Security group to allow port 22,80,443
resource "aws_security_group" "dest-security-group" {
  name        = "allow_tls 2"
  description = "Allow TLS inbound traffic 2"
  vpc_id      = aws_vpc.dest-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
  ingress {
    description      = "ICMP"
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
    }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web_2"
  }
}
# Create a network interface with an IP in the subnet 
resource "aws_network_interface" "nic2" {
  subnet_id       = aws_subnet.dest-subnet.id
  private_ips     = ["10.1.1.50"]
  security_groups = [aws_security_group.dest-security-group.id]

}
# Assign an elastic IP to the network interface
resource "aws_eip" "dest-eip" {
  vpc = true
  instance = aws_instance.dest-server.id
  network_interface = aws_network_interface.nic2.id
  associate_with_private_ip = "10.1.1.50"
  depends_on = [aws_internet_gateway.dest-gw]
}
# Create ubuntu server and install apache2
resource "aws_instance" "dest-server" {
    ami = "ami-0aa7d40eeae50c9a9"
    instance_type = "t2.micro"
    availability_zone = "us-east-1b"
    key_name = "access-key"
    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.nic2.id
    }
    tags = {
        Name = "destination-server"
    }
}
