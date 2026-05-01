# Public Subnet Outputs
output "vpc_id" {
  value = aws_vpc.qida_vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.qida_private_subnet[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.qida_private_subnet[*].id
}