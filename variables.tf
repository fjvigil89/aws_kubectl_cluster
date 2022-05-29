variable "cidr" {
  description = "Direccion IP privados a utilizar VPC de AWS"
  default     = "170.0.0.0/20"
}

variable "ssh_pub_path" {
  description = "Direccion de las llabes ssh publica"
  default     = "~/.ssh/id_rsa.pub"
}

variable "cluster_name" {
  default = "ages"
}

variable "project_name" {
  default = "Ages"
}

variable "region" {
  default = "eu-west-1"
}

variable "environment" {
  default = "dev"
}