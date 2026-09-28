resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "vpc"
  }
}
resource "aws_subnet" "public_sub_1" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"
  tags = {
    name = "public-sub-1"
  }
}
resource "aws_subnet" "public_sub_2" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "true"
  tags = {
    name = "public-sub-2"
  }
}
resource "aws_subnet" "private_sub_1" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "false"
  tags = {
    name = "private-sub-1"
  }
}
resource "aws_subnet" "private_sub_2" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "true"
   tags = {
    name = "private-sub-2"
  }
}
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    name = "vpc-igw"
  }
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_igw.id
  }
tags = {
  name = "public-rt"
}
}
resource "aws_route_table_association" "public_1" {
  subnet_id = aws_subnet.public_sub_1.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_2" {
  subnet_id = aws_subnet.public_sub_2.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_eip" "elastic_ip" {
  domain = "vpc"
  tags = {
    name = "elastic-ip"
  }
}
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.elastic_ip.id
  subnet_id = aws_subnet.public_sub_1.id
  tags = {
    name = "nat-gateway"
  }
  depends_on = [ aws_internet_gateway.vpc_igw ]
}
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    name = "private-rt"
  }
}
resource "aws_route_table_association" "private_1" {
  subnet_id = aws_subnet.private_sub_1.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_2" {
  subnet_id = aws_subnet.private_sub_2.id
  route_table_id = aws_route_table.private_rt.id
}
