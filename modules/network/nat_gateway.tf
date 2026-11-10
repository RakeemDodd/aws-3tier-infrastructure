resource "aws_eip" "nat_a" {
  domain = "vpc"

  tags = {
    Name = "nat-eip-a"
  }
}

resource "aws_eip" "nat_b" {
  count = var.second_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = {
    Name = "nat-eip-b"
  }
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name = "nat-gw-a"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat_b" {
  count = var.second_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat_b[count.index].id
  subnet_id     = aws_subnet.public_b.id

  tags = {
    Name = "nat-gw-b"
  }

  depends_on = [aws_internet_gateway.main]
}
