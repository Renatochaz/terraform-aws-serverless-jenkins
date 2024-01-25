###################################
###### PRIVATE SUBNET SETUP #######
###################################

resource "aws_eip" "nat_gateway_ip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "public_ntg" {
  allocation_id     = aws_eip.nat_gateway_ip.id
  connectivity_type = "public"
  subnet_id         = var.natg_public_subnet
}

resource "aws_route_table" "public_ntg_route_table" {
  vpc_id = var.vpc_id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public_ntg.id
  }
}

resource "aws_subnet" "private_subnet" {
  availability_zone = data.aws_subnet.natg_public_subnet.availability_zone
  cidr_block        = var.private_subnet_cidr
  vpc_id            = var.vpc_id
}


resource "aws_route_table_association" "instance" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.public_ntg_route_table.id
}
