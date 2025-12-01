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

# IP Elàstica per al NAT Gateway (vpc=true eliminat)
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

# Bucket S3 per al backup de claus públiques
resource "aws_s3_bucket" "key_backup" {
  bucket = "tf-proxyjump-key-backup-${aws_vpc.main.id}"
  force_destroy = true 
}

# Emmagatzema la clau pública del Bastió a S3 (Utilitzant arguments antics compatibles)
resource "aws_s3_bucket_object" "bastion_pubkey_backup" {
  bucket = aws_s3_bucket.key_backup.id
  key    = "bastion.pub"
  content = tls_private_key.bastion_key.public_key_openssh
  acl    = "private"
  content_type = "text/plain"
}

# Emmagatzema les claus públiques privades a S3 (N fitxers, Utilitzant arguments antics compatibles)
resource "aws_s3_bucket_object" "private_pubkeys_backup" {
  count  = var.private_instance_count
  bucket = aws_s3_bucket.key_backup.id
  key    = "private-${count.index + 1}.pub"
  content = tls_private_key.private_keys[count.index].public_key_openssh
  acl    = "private"
  content_type = "text/plain"
}


################################################################################
# 3. Security Groups (Grups de Seguretat)
################################################################################

# Security Group del Bastió
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.main.id
  name   = "bastion-sg"
  
  # Ingress: SSH des de la teva IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip] 
    description = "Allow SSH from users IP"
  }
  
  # Egress: Permet SSH cap a les subxarxes privades (necessari per al Bastió)
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [for subnet in aws_subnet.private : subnet.cidr_block]
    description = "Allow SSH to Private Subnets"
  }
  
  # Egress per a connexió a Internet (updates, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name = "Bastion SG"
  }
}

# Security Group Privat
resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.main.id
  name   = "private-sg"
  
  # Ingress: SSH des del Security Group del Bastió
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
    description = "Allow SSH from Bastion Host"
  }
  
  # Ingress: SSH des de si mateix (comunicació entre servidors privats)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
    description = "Allow SSH from other Private Servers (Self-Referencing)"
  }
  
  # Egress: Accés a Internet (a través del NAT Gateway)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name = "Private SG"
  }
}


################################################################################
# 4. Instàncies EC2 i Key Pairs
################################################################################

# Key Pair AWS per al Bastió
resource "aws_key_pair" "bastion_kp" {
  key_name   = "bastion-key"
  public_key = tls_private_key.bastion_key.public_key_openssh
}

# Key Pair AWS per a les Instàncies Privades
resource "aws_key_pair" "private_kps" {
  count      = var.private_instance_count
  key_name   = "private-key-${count.index + 1}"
  public_key = tls_private_key.private_keys[count.index].public_key_openssh
}

# IP Elàstica per al Bastió (IP fixa)
resource "aws_eip" "bastion_eip" {} 

# Instància Bastion Host (Pública)
resource "aws_instance" "bastion" {
  ami           = var.instance_ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.bastion_kp.key_name
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  
  # Assignació de l'EIP
  associate_public_ip_address = true
  
  tags = {
    Name = "Bastion-Host"
  }
}

# Associar l'EIP a la Instància Bastió
resource "aws_eip_association" "bastion_eip_assoc" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion_eip.id
}

# Instàncies Privades (N instàncies)
resource "aws_instance" "private" {
  count = var.private_instance_count
  
  ami           = var.instance_ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.private_kps[count.index].key_name
  # Selecciona la subxarxa privada corresponent
  subnet_id     = aws_subnet.private[count.index].id 
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  
  # No assignar IP pública
  associate_public_ip_address = false
  
  tags = {
    Name    = "Private-Server-${count.index + 1}"
    Subnet  = aws_subnet.private[count.index].tags.Name
  }
}

# Fitxers de clau privada locals
resource "local_file" "bastion_private_key" {
  content  = tls_private_key.bastion_key.private_key_pem
  filename = "bastion.pem"
  file_permission = "0400"
}

resource "local_file" "private_private_keys" {
  count    = var.private_instance_count
  content  = tls_private_key.private_keys[count.index].private_key_pem
  filename = "private-${count.index + 1}.pem"
  file_permission = "0400"
}