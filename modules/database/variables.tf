variable "name_prefix" {
  description = "Prefix for resource names, environment first (for example dev-3tier)"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the private subnets for the database subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the security group for the database"
  type        = string
}

variable "multi_az" {
  description = "Run a standby copy in a second Availability Zone. False in demo mode."
  type        = bool
}
