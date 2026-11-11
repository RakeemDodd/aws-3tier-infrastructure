data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "main" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # Stay within free CPU credits instead of paying for extra bursts
  credit_specification {
    cpu_credits = "standard"
  }

  # Require IMDSv2 tokens, which blocks credential theft through SSRF
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Encrypt the server's disk
  root_block_device {
    encrypted = true
  }

  # Startup script edits rebuild the instance, so the change actually runs
  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd mariadb105
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>3-Tier Infrastructure - EC2 Instance Running</h1><p>Deployed via Terraform.</p>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "${var.name_prefix}-ec2"
  }

  lifecycle {
    # New Amazon Linux releases don't replace a running instance.
    # Every fresh build still gets the latest image.
    ignore_changes = [ami]
  }
}
