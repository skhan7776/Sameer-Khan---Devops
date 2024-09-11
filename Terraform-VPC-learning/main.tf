#Create VPC|Subnets|EC2 instance using terraform

#we will take a look at how to do the following using terraform:
#Create a VPC and subnets
#Create an internet gateway and route table to make the subnet public
#Create security groups
#Create an ec2 instance on a public subnet and install nginx

  provider "aws" {
    profile = "default"
    region  = "us-east-1"
  }


#VPC and EC2 instance
#When setting up a new VPC to deploy EC2 instances, we usually follow these basic steps.
#Create a vpc
#Create subnets for different parts of the infrastructure
#Attach an internet gateway to the VPC
#Create a route table for a public subnet
#Create security groups to allow specific traffic
#Create ec2 instances on the subnets

#1. Create a vpc
#Resource: aws_vpc -->> https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

resource "aws_vpc" "terraform_custom_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Terraform Custom VPC"
  }
} 

#2. Create subnets for different parts of the infrastructure

#Resource: aws_subnet -->> https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet

resource "aws_subnet" "terraform_public_subnet" {
  vpc_id            = aws_vpc.Terraform_Custom_VPC.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1"

  tags = {
    Name = "Terraform Public Subnet"
  }
}

resource "aws_subnet" "terraform_private_subnet" {
  vpc_id            = aws_vpc.Terraform_Custom_VPC.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1"

  tags = {
    Name = "Terraform Private Subnet"
  }
} 

#Attach an internet gateway to the VPC

#Resource: aws_internet_gateway -->> https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway

resource "aws_internet_gateway" "terraform_ig" {
  vpc_id = aws_vpc.terraform_custom_vpc.id

  tags = {
    Name = "Terraform Internet Gateway"
  }
} 

#4. Create a route table for a public subnet
#Resource: aws_route_table -->> https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.terraform_custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.terraform_ig.id
  }

  tags = {
    Name = "Public Route Table"
  }
} 

#Resource: aws_route_table_association -->> https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association

resource "aws_route_table_association" "public_1_route_a" {
  subnet_id      = aws_subnet.terraform_public_subnet.id
  route_table_id = aws_route_table.public_route.id
} 

#5. Create security groups to allow specific traffic

#Resource: aws_security_group -->> https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

resource "aws_security_group" "web_sg" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.terraform_custom_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
} 

#Resource: aws_instance -->> https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#associate_public_ip_address

resource "aws_instance" "web_instance" {
  ami           = "ami-0533f2ba8a1995cf9"
  instance_type = "t2.micro"
  key_name = "Firstkeypair"

  subnet_id                   = aws_subnet.terraform_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
}