resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.name_prefix}-db-subnets"
  }
}

resource "aws_db_instance" "main" {
  identifier             = "${var.name_prefix}-db"
  allocated_storage      = 10
  storage_encrypted      = true
  db_name                = "appdb"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  multi_az               = var.multi_az

  # RDS creates the master password, keeps it in Secrets Manager and rotates it.
  # The password never appears in code, on a laptop, or in Terraform state.
  manage_master_user_password = true

  tags = {
    Name = "${var.name_prefix}-db"
  }
}
