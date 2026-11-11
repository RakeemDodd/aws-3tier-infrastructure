variable "name_prefix" {
  description = "Prefix for resource names, environment first (for example dev-3tier)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC the security groups belong to"
  type        = string
}
