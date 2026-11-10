output "alb_sg_id" {
  description = "ID of the load balancer security group"
  value       = aws_security_group.alb_sg.id
}

output "ec2_sg_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2_sg.id
}

output "rds_sg_id" {
  description = "ID of the database security group"
  value       = aws_security_group.rds_sg.id
}
