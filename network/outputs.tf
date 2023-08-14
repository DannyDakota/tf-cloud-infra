output "vpc_id" {
  value = aws_vpc.aws_vpc.id
}

output "private_subnet_1_id" {
  value = aws_subnet.private_subnet_1.id
}

output "private_subnet_2_id" {
  value = aws_subnet.private_subnet_2.id
}

output "default_security_group_id" {
  value = aws_security_group.security_group.id
}

output "alb_security_group_id" {
  value = aws_security_group.alb_security_group.id
}
