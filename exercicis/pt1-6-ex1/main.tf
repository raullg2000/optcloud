# main.tf

################################################################################
# 1. Xarxa i Connectivitat (VPC, Subnets, Gateways)
################################################################################

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "Bastion-ProxyJump-VPC"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "IGW"
  }
}

# Subxarxa Pública (per al Bastió i NAT Gateway)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1) # 10.0.1.0/24
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true
  tags = {
    Name    = "Public Subnet (AZ1)"
    Tier    = "Public"
  }
}

# Taula de rutes pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Public Route Table"
  }
}

# Associació de la subxarxa pública amb la taula de rutes pública
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# IP Elàstica per al NAT Gateway
resource "aws_eip" "nat" {}

# NAT Gateway (a la subxarxa pública)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "NAT Gateway"
  }
  depends_on = [aws_internet_gateway.igw]
}

# Subxarxes Privades (N subxarxes, rotació d'AZs)
resource "aws_subnet" "private" {
  count = var.private_instance_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 2) 
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = false

  tags = {
    Name    = "Private Subnet ${count.index + 1} (${var.availability_zones[count.index % length(var.availability_zones)]})"
    Tier    = "Private"
  }
}

# Taules de rutes privades (una per a cada subxarxa privada)
resource "aws_route_table" "private" {
  count = var.private_instance_count
  
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id 
  }
  tags = {
    Name = "Private Route Table ${count.index + 1}"
  }
}

# Associació de les subxarxes privades amb les seves taules de rutes
resource "aws_route_table_association" "private" {
  count          = var.private_instance_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


################################################################################
# 2. Gestió de Claus SSH (TLS Provider) i S3
################################################################################

# Parell de claus del Bastió
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Parells de claus Privades (N claus)
resource "tls_private_key" "private_keys" {
  count = var.private_instance_count
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Bucket S3 per