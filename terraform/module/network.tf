data "aws_availability_zones" "available" {}

# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      "Name" = "${var.base_name}-vpc"
    },
    var.tags
  )

}

# サブネット
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = merge(
    {
      "Name" = "${var.base_name}-public-subnet"
    },
    var.tags
  )

}

# インターネットゲートウェイ
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      "Name" = "${var.base_name}-igw"
    },
    var.tags
  )
}

# ルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      "Name" = "${var.base_name}-public-subnet"
    },
    var.tags
  )
}

resource "aws_route" "route-ipv4" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}