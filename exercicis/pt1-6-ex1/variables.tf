# variables.tf
variable "aws_region" {
  description = "Región AWS a utilizar."
  type        = string
  default     = "us-east-1"
}

variable "private_instance_count" {
  description = "Número de instancias privadas (y subredes) a crear."
  type        = number
  default     = 2
}

variable "vpc_cidr" {
  description = "Bloque CIDR para la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_ami" {
  description = "AMI de la instancia EC2."
  type        = string
  default     = "ami-0fa3fe0fa7920f68e"
}

variable "instance_type" {
  description = "Tipo de instancia EC2."
  type        = string
  default     = "t3.micro"
}

variable "allowed_ip" {
  description = "IP pública de tu ordenador (CIDR) para el acceso SSH al Bastión."
  type        = string
  default     = "2.136.30.53/32"
}

variable "availability_zones" {
  description = "Zonas de Disponibilidad a utilizar (máximo 3)."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}