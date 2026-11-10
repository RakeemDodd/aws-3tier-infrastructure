output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, in AZ order (a, b)"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets, in AZ order (a, b)"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "nat_gateway_ips" {
  description = "Public IPs of the NAT gateways"
  value       = concat([aws_eip.nat_a.public_ip], aws_eip.nat_b[*].public_ip)
}
