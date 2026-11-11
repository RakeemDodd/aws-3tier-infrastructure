output "alb_dns_name" {
  description = "The DNS name to access the load balancer"
  value       = module.load_balancer.dns_name
}

output "rds_endpoint" {
  description = "The RDS instance endpoint"
  value       = module.database.endpoint
}

output "ec2_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = module.compute.private_ip
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.network.private_subnet_ids
}

output "nat_gateway_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = module.network.nat_gateway_ips
}
