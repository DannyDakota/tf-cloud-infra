resource "aws_vpc" "aws_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.aws_vpc.id
  availability_zone = var.availability_zone_1
  cidr_block        = "10.0.1.0/24"
}
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.aws_vpc.id
  availability_zone = var.availability_zone_1
  cidr_block        = "10.0.2.0/24"
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.aws_vpc.id
  availability_zone = var.availability_zone_2
  cidr_block        = "10.0.3.0/24"
}

resource "aws_security_group" "security_group" {
  vpc_id = aws_vpc.aws_vpc.id

  ingress {
    from_port       = var.application_port
    to_port         = var.application_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_security_group" {
  vpc_id = aws_vpc.aws_vpc.id

  ingress {
    from_port   = var.application_port
    to_port     = var.application_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------- Internet Gateway ----------------------
resource "aws_internet_gateway" "my_internet_gateway" {
  vpc_id = aws_vpc.aws_vpc.id

  tags = {
    Name = "MyInternetGateway"
  }
}

# ---------------------- Elastic IP ----------------------
resource "aws_eip" "aws_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.my_internet_gateway]
}

# ---------------------- NAT Gateway ----------------------
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.aws_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  depends_on    = [aws_internet_gateway.my_internet_gateway]

  tags = {
    Name = "gw NAT"
  }
}


# ---------------------- Route Table ----------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.aws_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_internet_gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.my_internet_gateway.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.aws_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "PrivateRouteTable"
  }
}

# ---------------------- Route Table Association ----------------------
resource "aws_route_table_association" "public_rt_a" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_1_rt_a" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_2_rt_a" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}
