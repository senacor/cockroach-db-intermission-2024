resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = merge(local.default_tags, {
    Name = "cockroach-intermission-2024"
  })
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.default_tags, {
    Name = "cockroach-intermission-2024"
  })
}

resource "aws_route" "this" {
  route_table_id = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "this" {
  count = var.number_of_available_zones
  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.this.id
}