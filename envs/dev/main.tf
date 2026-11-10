module "network" {
  source = "../../modules/network"

  second_nat_gateway = local.second_nat_gateway
}

module "security" {
  source = "../../modules/security"

  vpc_id = module.network.vpc_id
}

module "compute" {
  source = "../../modules/compute"

  subnet_id         = module.network.private_subnet_ids[0]
  security_group_id = module.security.ec2_sg_id
}

module "database" {
  source = "../../modules/database"

  subnet_ids        = module.network.private_subnet_ids
  security_group_id = module.security.rds_sg_id
  db_password       = var.db_password
  multi_az          = local.db_multi_az
}

module "load_balancer" {
  source = "../../modules/load_balancer"

  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.public_subnet_ids
  security_group_id = module.security.alb_sg_id
  instance_id       = module.compute.instance_id
}
