###1.Register AWS provider 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.66.1"
    }
  }
}

provider "aws" {
  region = "us-east-1"

}

###CREATING VPC###
resource "aws_vpc" "lab_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "lab_vpc"
  }
}

##CREATING PUBLIC SUBNET###
resource "aws_subnet" "lab_public_subnet" {
  vpc_id     = aws_vpc.lab_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "lab_public_subnet"
  }
}

##creating private subnet###
resource "aws_subnet" "lab_private_subnet" {
  vpc_id     = aws_vpc.lab_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "lab_private_subnet"
  }
}

##creating security groups### ##what kind of traffic can come in and out at instance level#
resource "aws_security_group" "lab_sg" {
  name        = "lab_sg"
  description = "Allow SSH traffic" ##allow encrypted traffic##
  vpc_id      = aws_vpc.lab_vpc.id  ##describing which vpc it is located in##

  ingress { ##allow port 22 from anywhere##
    description = "Allow SSH"
    from_port   = 22 ##used by default for SSH connections (give users a secure way to access computer over an unsecure network)###
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.lab_vpc.cidr_block, "0.0.0.0/0"]
  }

  egress { ##allow output traffic for any port towards any ip##
    from_port   = 0
    to_port     = 0
    protocol    = "-1" ##always use to specify all protocols##
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

##create internet gateway##
resource "aws_internet_gateway" "lab_igw" {
  vpc_id = aws_vpc.lab_vpc.id

  tags = {
    Name = "lab_igw"
  }
}

resource "aws_eip" "lab_elastic_ip" { ##elastic ip=used for failover,will remap address to another instance that is available##
  vpc = true
}

resource "aws_nat_gateway" "lab_nat_gateway" { ##nat gateway placed in public subnet##
  allocation_id = aws_eip.lab_elastic_ip.id    ## assigned elastic ip
  subnet_id     = aws_subnet.lab_public_subnet.id

  tags = {
    Name = "Lab NAT Gateway"
  }
  depends_on = [aws_internet_gateway.lab_igw] #depends on=allows you to create a dependency between resources (nat depends on IGW)
}

##create route tables##
resource "aws_route_table" "lab_vpc_public_RouteTable" {
  vpc_id = aws_vpc.lab_vpc.id

  route { ## this route goes to internet##
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab_igw.id
  }

  tags = {
    Name = "VPC_Public_RouteTable"
  }
}

resource "aws_route_table" "lab_vpc_private_RouteTable" {
  vpc_id = aws_vpc.lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.lab_nat_gateway.id
  }

  tags = {
    Name = "VPC_Private_RouteTable"
  }
}

resource "aws_route_table_association" "lab_public_RouteTable_Assoc" { ##Must associate with appropriate subnet with routetable##
  subnet_id      = aws_subnet.lab_public_subnet.id
  route_table_id = aws_route_table.lab_vpc_public_RouteTable.id
}

resource "aws_route_table_association" "lab_private_RouteTable_Assoc" {
  subnet_id      = aws_subnet.lab_private_subnet.id
  route_table_id = aws_route_table.lab_vpc_private_RouteTable.id
}


