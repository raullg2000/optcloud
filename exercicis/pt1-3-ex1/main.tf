#Define la region
provider "aws" {
	region = "us-east-1"
}
# Define la instancia EC2 1
resource "aws_instance" "Instancia_1" {
  ami           = "ami-052064a798f08f0d3"
  instance_type = "t3.micro"
  tags = {
    Name = "Instancia Raul 1"
  }
}

# Define la instancia EC2 2
resource "aws_instance" "Instancia_2" {
  ami           = "ami-052064a798f08f0d3"
  instance_type = "t3.micro"
  tags = {
    Name = "Instancia Raul 2"
  }
}