locals {
  # Demo mode turns off the costly redundancy. The network still spans 2 AZs,
  # because the load balancer and the database subnet group require it.
  second_nat_gateway = !var.demo_mode
  db_multi_az        = !var.demo_mode
}
