variable "second_nat_gateway" {
  description = "Create a second NAT gateway so each Availability Zone has its own. False in demo mode."
  type        = bool
}
