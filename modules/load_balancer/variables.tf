variable "name_prefix" {
  description = "Prefix for resource names, environment first (for example dev-3tier)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC for the target group"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the public subnets for the load balancer"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the security group for the load balancer"
  type        = string
}

variable "instance_id" {
  description = "ID of the EC2 instance to send traffic to"
  type        = string
}
