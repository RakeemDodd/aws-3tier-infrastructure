variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "demo_mode" {
  description = "Cheaper practice build: one NAT gateway and a single-AZ database. Off in prod, which runs the full high-availability design."
  type        = bool
  default     = false
}
