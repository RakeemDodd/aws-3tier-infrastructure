variable "name_prefix" {
  description = "Prefix for resource names, environment first (for example dev-3tier)"
  type        = string
}

variable "vpc_cidr" {
  description = "Address range for the VPC. Subnets are carved from it as /24s"
  type        = string
}

variable "second_nat_gateway" {
  description = "Create a second NAT gateway so each Availability Zone has its own. False in demo mode."
  type        = bool
}
