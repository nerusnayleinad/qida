# VPC
resource "aws_vpc" "qida_vpc" {
  cidr_block = var.vpc_cidr
  
  tags = merge(var.tags, {
    Name     = "vpc-qida-${var.name_suffix}"
  })
}

# Public subnets
resource "aws_subnet" "qida_public_subnet" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.qida_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "public-subnet-${count.index + 1}-${var.name_suffix}"
    Type = "public"
  })
}

# Private subnets
resource "aws_subnet" "qida_private_subnet" {
  count = length(var.private_subnet_cidrs)

  vpc_id                  = aws_vpc.qida_vpc.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "private-subnet-${count.index + 1}-${var.name_suffix}"
    Type = "private"
  })
}

# adding internet gateway for external communication
resource "aws_internet_gateway" "qida_internet_gateway" {
  provider = aws
  vpc_id = aws_vpc.qida_vpc.id

  tags = merge(var.tags, {
    Name = "igw-${var.name_suffix}"
  })

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

# create external route to IGW
resource "aws_route" "external_route" {
  provider               = aws
  route_table_id         = aws_vpc.qida_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.qida_internet_gateway.id
}

resource "aws_eip" "qida_eip_nat" {
  count  = length(aws_subnet.qida_private_subnet)
  
  domain = "vpc"
}

# NAT gateway
resource "aws_nat_gateway" "qida_nat_gateway" {
  count = length(aws_eip.qida_eip_nat)
  allocation_id = aws_eip.qida_eip_nat[count.index].id
  subnet_id     = aws_subnet.qida_private_subnet[count.index].id

  tags = merge(var.tags, {
    Name = "nat-gw-${var.name_suffix}"
  })

  depends_on = [aws_internet_gateway.qida_internet_gateway]
}

resource "aws_route_table" "qida_rt_natgw_to_igw" {
  count = length(aws_nat_gateway.qida_nat_gateway)
  vpc_id = aws_vpc.qida_vpc.id

  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.qida_nat_gateway[count.index].id
  }

  tags = merge(var.tags, {
    Name = "rt-natgw-to-igw-${var.name_suffix}"
  })
}

resource "aws_route_table_association" "qida_rt_association" {
  count = length(aws_subnet.qida_private_subnet)
  subnet_id = aws_subnet.qida_private_subnet[count.index].id
  route_table_id = aws_route_table.qida_rt_natgw_to_igw[count.index].id
}