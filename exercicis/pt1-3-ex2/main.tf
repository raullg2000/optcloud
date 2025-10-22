provider "aws" {
	region = "us-east-1"
}
#CREAR VPC


#CREAR SUBNET
	resource "aws_subnet" "subnet_A" {
	vpc_id = aws_vpc.vpc_myrna.id
	cidr_block = "10.0.32.0/25"
	availability_zone = "us-east-1a"
	map_public_ip_on_launch = true

	tags = {
	 Name = "Subnet A"
	}
}


#CREAR INSTANCIAS
resource "aws_instance" "instancias_A-1" {
  count = 2
  ami = ""
  instance_type = "t3.micro"
  subnet_id = aws_subnet.subnet_A.id
  tags = {
	Name = "instanciaA-${count.index + 1}"
  }
}