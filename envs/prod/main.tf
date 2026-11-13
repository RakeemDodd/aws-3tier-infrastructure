module "network" {
  source = "../../modules/network"

  name_prefix        = local.name_prefix
  vpc_cidr           = local.vpc_cidr
  second_nat_gateway = local.second_nat_gateway
}

module "security" {
  source = "../../modules/security"

  name_prefix = local.name_prefix
  vpc_id      = module.network.vpc_id
}

module "compute" {
  source = "../../modules/compute"

  name_prefix       = local.name_prefix
  subnet_id         = module.network.private_subnet_ids[0]
  security_group_id = module.security.ec2_sg_id
}

module "database" {
  source = "../../modules/database"

  name_prefix       = local.name_prefix
  subnet_ids        = module.network.private_subnet_ids
  security_group_id = module.security.rds_sg_id
  multi_az          = local.db_multi_az
}

module "load_balancer" {
  source = "../../modules/load_balancer"

  name_prefix       = local.name_prefix
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.public_subnet_ids
  security_group_id = module.security.alb_sg_id
  instance_id       = module.compute.instance_id
}
