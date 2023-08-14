resource "aws_vpc" "aws_vpc" {}


resource "aws_subnet" "private_subnet_1" {
    vpc_id = aws_vpc.aws_vpc.id
    availability_zone = var.availability_zone_1
}

resource "aws_subnet" "public_subnet_2" {
    vpc_id = aws_vpc.aws_vpc.id
    availability_zone = var.availability_zone_2
}

resource "aws_security_group" "security_group" {
    vpc_id = aws_vpc.aws_vpc.id

    ingress {
        from_port = var.application_port
        to_port = var.application_port
        protocol = "tcp"
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
        from_port = var.application_port
        to_port = var.application_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}