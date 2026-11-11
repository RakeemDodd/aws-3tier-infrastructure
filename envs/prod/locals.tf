locals {
  environment = "prod"
  name_prefix = "${local.environment}-3tier"
  vpc_cidr    = "10.1.0.0/16"

  # Prod runs the full design by default: a NAT gateway per AZ and a
  # Multi-AZ database. Demo mode can still be turned on for a cheap rehearsal.
  second_nat_gateway = !var.demo_mode
  db_multi_az        = !var.demo_mode
}
