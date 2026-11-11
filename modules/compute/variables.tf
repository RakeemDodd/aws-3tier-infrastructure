variable "name_prefix" {
  description = "Prefix for resource names, environment first (for example dev-3tier)"
  type        = string
}

variable "subnet_id" {
  description = "ID of the private subnet to launch the instance in"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group for the instance"
  type        = string
}
