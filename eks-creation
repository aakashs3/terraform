terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.66.0"
    }
  }
}
provider "aws" {
 region = "ap-south-1"
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.66.0"
    }
  }
}
provider "aws" {
  # Configuration options
}

# vpc creation part

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "vpc"
  }
}
resource "aws_subnet" "public_subnet_1" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    name = "public-subnet-1"
  }
}
resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    name = "public-subnet-2"
  }
}
resource "aws_subnet" "private_subnet_1" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    name = "private-subnet-1"
  }
}
resource "aws_subnet" "private_subnet_2" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    name = "private-subnet-2"
  }
}
resource "aws_internet_gateway" "vpc_internet" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    name = "vpc-internet"
  }
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_internet.id
  }
  tags = {
    name = "public-rt"
  }
}
resource "aws_route_table_association" "public_sub_1" {
  subnet_id = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_sub_2" {
  subnet_id = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    name = "nat-eip"
  }
}
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public_subnet_1.id
  tags = {
    name = "nat-gateway"
  }
  depends_on = [ aws_internet_gateway.vpc_internet ]
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
resource "aws_route_table_association" "private_sub_1" {
  subnet_id = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_sub_2" {
  subnet_id = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# role and policy creation/attachment part

resource "aws_iam_role" "eks_main_role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode(
    {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "eks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
  )
}
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role = aws_iam_role.eks_main_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_role" "worker_node_rule" {
  name = "worker-node-rule"
  assume_role_policy = jsonencode(
    {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com"
                ]
            }
        }
    ]
}
  )
}
resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  role = aws_iam_role.worker_node_rule.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role = aws_iam_role.worker_node_rule.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly"
}
resource "aws_iam_role_policy_attachment" "cni_policy" {
  role = aws_iam_role.worker_node_rule.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "ecr_policy_2" {
  role = aws_iam_role.worker_node_rule.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# eks creation part

resource "aws_eks_cluster" "my_new_eks" {
  name = "my-new-eks"
  role_arn = aws_iam_role.eks_main_role.arn
  vpc_config {
    subnet_ids = [
        aws_subnet.private_subnet_1.id,
        aws_subnet.private_subnet_2.id
    ]
  }
  depends_on = [ aws_iam_role_policy_attachment.eks_cluster_policy ]
}

# eks worker node creation part

resource "aws_eks_node_group" "nodes" {
  cluster_name = aws_eks_cluster.my_new_eks.name
  node_group_name = "my-node-group"
  node_role_arn = aws_iam_role.worker_node_rule.arn
  subnet_ids = [
    aws_subnet.private_subnet_1,
    aws_subnet.private_subnet_2
  ]
instance_types = ["m7i-flex.large"]
scaling_config {
  desired_size = 2
  max_size = 2
  min_size = 1
}
depends_on = [ aws_iam_role_policy_attachment.worker_node_policy,
                aws_iam_role_policy_attachment.cni_policy,
                aws_iam_role_policy_attachment.ecr_policy,
                aws_iam_role_policy_attachment.ecr_policy_2 ]
}
