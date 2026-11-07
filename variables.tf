variable "db_password" {
  description = "RDS DB master password"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "demo_mode" {
  description = "Cheaper practice build: one NAT gateway and a single-AZ database. Set to false for the full high-availability design."
  type        = bool
  default     = true
}
