output "alb_dns_name" {
  description = "The DNS name to access the load balancer"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "The RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "ec2_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "nat_gateway_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = [aws_eip.nat_a.public_ip, aws_eip.nat_b.public_ip]
}
