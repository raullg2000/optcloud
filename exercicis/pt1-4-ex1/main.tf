#1. Proveïdor i regió
provider "aws" {
  region = "us-east-1"
}

#2. VPC
resource "aws_vpc" "vpc_03" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC-03"
  }
}

#3. SUBXARXES PÚBLIQUES

#Public Subnet A
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.vpc_03.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true # IP pública automàtica

  tags = {
    Name = "Public-Subnet-A"
  }
}

#Public Subnet B
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.vpc_03.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true # IP pública automàtica

  tags = {
    Name = "Public-Subnet-B"
  }
}

#4. INTERNET GATEWAY I TAULA DE ROUTES

#Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_03.id
  tags = {
    Name = "VPC-03-IGW"
  }
}

#Taula de rutes pública
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_03.id
  tags = {
    Name = "Public-Route-Table"
  }
}

#Ruta per defecte
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

#Associació de la Taula de Rutes a la Subnet A
resource "aws_route_table_association" "a_association" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

#Associació de la Taula de Rutes a la Subnet B
resource "aws_route_table_association" "b_association" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

#5. GRUP DE SEGURETAT
resource "aws_security_group" "sg_public" {
  vpc_id = aws_vpc.vpc_03.id
  name   = "SG-Public-Access"
  
  #SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #ICMP
  ingress {
    from_port   = -1 
    to_port     = -1 
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.vpc_03.cidr_block]
  }

  #Qualsevol destinació
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Public-Access"
  }
}

#6. INSTÀNCIES EC2

# Instància ec2-a
resource "aws_instance" "ec2_a" {
  ami             = "ami-07860a2d7eb515d9a"
  instance_type   = "t3.micro"
  subnet_id       = aws_subnet.public_a.id
  key_name        = "vockey"
  vpc_security_group_ids = [aws_security_group.sg_public.id] 
  
  tags = {
    Name = "ec2-a"
  }
}

# Instància ec2-b
resource "aws_instance" "ec2_b" {
  ami             = "ami-07860a2d7eb515d9a"
  instance_type   = "t3.micro"
  subnet_id       = aws_subnet.public_b.id
  key_name        = "vockey"
  vpc_security_group_ids = [aws_security_group.sg_public.id] 
  
  tags = {
    Name = "ec2-b"
  }
}