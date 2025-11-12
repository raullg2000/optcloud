variable "region" {
  type        = string
  default     = "eu-west-1" 
}

variable "available_azs" {
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "projecte_raul" {
  type        = string
  default     = "ProjecteTerraformRaul"
}

variable "instance_count" {
  type        = number
  default     = 1
}

variable "subnet_count" {
  type        = number
  default     = 2
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
}

variable "instance_ami" {
  type        = string
  default     = "ami-0157af9aea2eef346" 
}

variable "create_s3_bucket" {
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "my_ip" {
  type        = string
  default     = "0.0.0.0/0"
}