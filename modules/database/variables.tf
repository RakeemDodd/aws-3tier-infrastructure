variable "subnet_ids" {
  description = "IDs of the private subnets for the database subnet group"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the security group for the database"
  type        = string
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Run a standby copy in a second Availability Zone. False in demo mode."
  type        = bool
}
