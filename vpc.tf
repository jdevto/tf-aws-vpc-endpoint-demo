# VPC Configuration
resource "aws_vpc" "example" {
  cidr_block           = var.vpc_network.entire_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = local.name }
}

# Public & Private Subnets
resource "aws_subnet" "public" {
  count             = length(var.vpc_network.public_subnets)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  cidr_block        = var.vpc_network.public_subnets[count.index]
  vpc_id            = aws_vpc.example.id

  tags = { Name = "${local.name}-public-${element(data.aws_availability_zones.available.names, count.index)}" }
}

resource "aws_subnet" "private" {
  count             = length(var.vpc_network.private_subnets)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  cidr_block        = var.vpc_network.private_subnets[count.index]
  vpc_id            = aws_vpc.example.id

  tags = { Name = "${local.name}-private-${element(data.aws_availability_zones.available.names, count.index)}" }
}

# Internet Gateway for Public Traffic
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
  tags   = { Name = local.name }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "example" {
  domain = "vpc"
  tags   = { Name = local.name }
}

# NAT Gateway for Private Subnets
resource "aws_nat_gateway" "example" {
  allocation_id = aws_eip.example.id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.example]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  tags = { Name = "${local.name}-public" }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.example.id
  }

  tags = { Name = "${local.name}-private" }
}

# Associate Route Tables
resource "aws_route_table_association" "public" {
  count = length(var.vpc_network.public_subnets)

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_route_table_association" "private" {
  count = length(var.vpc_network.private_subnets)

  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private[count.index].id
}

# Security Group for EC2 Instance Connect
resource "aws_security_group" "ec2_connect" {
  name        = "${local.name}-sg"
  description = "Allow SSH access from EC2 Instance Connect"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.my_public_ip.response_body}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-ec2-connect" }
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name}-vpc-endpoints"
  description = "Allow HTTPS traffic for AWS service VPC Endpoints"
  vpc_id      = aws_vpc.example.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.vpc_network.private_subnets
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-vpc-endpoints" }
}

# AWS Service VPC Endpoints
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.example.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = { Name = "${local.name}-ssm-endpoint" }
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = aws_vpc.example.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = { Name = "${local.name}-ssm-messages-endpoint" }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.example.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = { Name = "${local.name}-ec2-messages-endpoint" }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.example.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = { Name = "${local.name}-logs-endpoint" }
}

# EC2 Instance Connect Endpoint
resource "aws_ec2_instance_connect_endpoint" "example" {
  subnet_id          = element(aws_subnet.private[*].id, 0)
  security_group_ids = [aws_security_group.ec2_connect.id]

  tags = { Name = local.name }
}
