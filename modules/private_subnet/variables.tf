variable "natg_public_subnet" {
  description = "ID of a public subnet to route the Nat Gateway"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the Jenkins will be deployed."
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block of the private subnet."
  type        = string
}