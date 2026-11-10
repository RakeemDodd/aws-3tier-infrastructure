# Records where each resource moved when the flat code was split into modules.
# Terraform renames these in state instead of destroying and recreating them.
# Keep these blocks: removing one is a breaking change for any state that
# still uses the old address.

# Network
moved {
  from = aws_vpc.main
  to   = module.network.aws_vpc.main
}

moved {
  from = aws_subnet.public_a
  to   = module.network.aws_subnet.public_a
}

moved {
  from = aws_subnet.public_b
  to   = module.network.aws_subnet.public_b
}

moved {
  from = aws_subnet.private_a
  to   = module.network.aws_subnet.private_a
}

moved {
  from = aws_subnet.private_b
  to   = module.network.aws_subnet.private_b
}

moved {
  from = aws_internet_gateway.main
  to   = module.network.aws_internet_gateway.main
}

moved {
  from = aws_eip.nat_a
  to   = module.network.aws_eip.nat_a
}

moved {
  from = aws_eip.nat_b
  to   = module.network.aws_eip.nat_b
}

moved {
  from = aws_nat_gateway.nat_a
  to   = module.network.aws_nat_gateway.nat_a
}

moved {
  from = aws_nat_gateway.nat_b
  to   = module.network.aws_nat_gateway.nat_b
}

moved {
  from = aws_route_table.public
  to   = module.network.aws_route_table.public
}

moved {
  from = aws_route_table.private_a
  to   = module.network.aws_route_table.private_a
}

moved {
  from = aws_route_table.private_b
  to   = module.network.aws_route_table.private_b
}

moved {
  from = aws_route_table_association.public_a
  to   = module.network.aws_route_table_association.public_a
}

moved {
  from = aws_route_table_association.public_b
  to   = module.network.aws_route_table_association.public_b
}

moved {
  from = aws_route_table_association.private_a
  to   = module.network.aws_route_table_association.private_a
}

moved {
  from = aws_route_table_association.private_b
  to   = module.network.aws_route_table_association.private_b
}

# Security
moved {
  from = aws_security_group.alb_sg
  to   = module.security.aws_security_group.alb_sg
}

moved {
  from = aws_security_group.ec2_sg
  to   = module.security.aws_security_group.ec2_sg
}

moved {
  from = aws_security_group.rds_sg
  to   = module.security.aws_security_group.rds_sg
}

# Compute
moved {
  from = aws_iam_role.ec2_ssm_role
  to   = module.compute.aws_iam_role.ec2_ssm_role
}

moved {
  from = aws_iam_role_policy_attachment.ssm_policy
  to   = module.compute.aws_iam_role_policy_attachment.ssm_policy
}

moved {
  from = aws_iam_instance_profile.ec2_profile
  to   = module.compute.aws_iam_instance_profile.ec2_profile
}

moved {
  from = aws_instance.main
  to   = module.compute.aws_instance.main
}

# Database
moved {
  from = aws_db_subnet_group.main
  to   = module.database.aws_db_subnet_group.main
}

moved {
  from = aws_db_instance.main
  to   = module.database.aws_db_instance.main
}

# Load balancer
moved {
  from = aws_lb.main
  to   = module.load_balancer.aws_lb.main
}

moved {
  from = aws_lb_target_group.main
  to   = module.load_balancer.aws_lb_target_group.main
}

moved {
  from = aws_lb_target_group_attachment.main
  to   = module.load_balancer.aws_lb_target_group_attachment.main
}

moved {
  from = aws_lb_listener.main
  to   = module.load_balancer.aws_lb_listener.main
}
