## Xarxa i Subxarxes

#VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.projecte_raul}-VPC"
  }
}

#Internet Gateway (IGW)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.projecte_raul}-IGW"
  }
}

#Creació de Subnets Públiques i Privades
resource "aws_subnet" "public" {
  count             = length(var.available_azs) 
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index * 2) 
  vpc_id            = aws_vpc.main.id
  map_public_ip_on_launch = true 
  availability_zone = var.available_azs[count.index] 

  tags = {
    Name = "${var.projecte_raul}-PublicSubnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.available_azs)
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index * 2 + 1)
  vpc_id            = aws_vpc.main.id
  availability_zone = var.available_azs[count.index]

  tags = {
    Name = "${var.projecte_raul}-PrivateSubnet-${count.index + 1}"
  }
}

#Taula de Rutes Públiques
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.projecte_raul}-PublicRouteTable"
  }
}

#Associació de la Taula de Rutes amb les Subnets Públiques
resource "aws_route_table_association" "public" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#Taula de Rutes Privades
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.projecte_raul}-PrivateRouteTable"
  }
}

#Associació de la Taula de Rutes amb les Subnets Privades
resource "aws_route_table_association" "private" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}


## Instàncies EC2

#Security Group
resource "aws_security_group" "main" {
  name        = "${var.projecte_raul}-SG"
  vpc_id      = aws_vpc.main.id

  # Regla 1: Permet HTTP (port 80) des de qualsevol IP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla 2: Permet SSH (port 22) només des de la IP de l'usuari
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Regla 3: Permet tot el tràfic dins de la VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" 
    cidr_blocks = [var.vpc_cidr]
  }

  # Regla 5: Permet tot el tràfic de sortida 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.projecte_raul}-SG"
  }
}

#Creació d'Instàncies Públiques
resource "aws_instance" "public" {
  count         = var.instance_count * var.subnet_count
  ami           = var.instance_ami
  instance_type = var.instance_type
  
  subnet_id = aws_subnet.public[count.index % var.subnet_count].id

  security_groups = [aws_security_group.main.id]
  
  depends_on = [
    aws_route_table_association.public
  ]

  tags = {
    Name    = "${var.projecte_raul}-Public-Instance-${count.index + 1}"
    Project = var.projecte_raul
  }
}

#Creació d'Instàncies Privades
resource "aws_instance" "private" {
  count         = var.instance_count * var.subnet_count
  ami           = var.instance_ami
  instance_type = var.instance_type
  
  subnet_id = aws_subnet.private[count.index % var.subnet_count].id

  security_groups = [aws_security_group.main.id]
  
  tags = {
    Name    = "${var.projecte_raul}-Private-Instance-${count.index + 1}"
    Project = var.projecte_raul
  }
}



## Bucket S3 Condicional

#Bucket S3 (Creació Condicional)
resource "aws_s3_bucket" "conditional_bucket" {
  count  = var.create_s3_bucket ? 1 : 0 
  
  bucket = "${lower(var.projecte_raul)}-tf-conditional-bucket-g4d8s"

  tags = {
    Name    = "Conditional-Bucket"
    Project = var.projecte_raul
  }
}