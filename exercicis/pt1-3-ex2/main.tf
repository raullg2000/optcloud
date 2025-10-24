provider "aws" {
  region = "us-east-1"
}

#LA VPC (El teu 10.0.0.0/16)
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC-Exercici"
  }
}

#LAS SUBNETS
resource "aws_subnet" "a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.32.0/25"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet-A"
  }
}

resource "aws_subnet" "b" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.30.0/23"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "Subnet-B"
  }
}

resource "aws_subnet" "c" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.33.0/28"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "Subnet-C"
  }
}

#LES INSTÀNCIES (t3.micro, 2 per subnet)
resource "aws_instance" "instancies_a" {
  count         = 2
  ami           = "ami-0341d95f75f311023"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.a.id
  tags = {
    Name = "InstanciaA-${count.index + 1}"
  }
}

resource "aws_instance" "instancies_b" {
  count         = 2
  ami           = "ami-0341d95f75f311023"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.b.id
  tags = {
    Name = "InstanciaB-${count.index + 1}"
  }
}

resource "aws_instance" "instancies_c" {
  count         = 2
  ami           = "ami-0341d95f75f311023"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.c.id
  tags = {
    Name = "InstanciaC-${count.index + 1}"
  }
}