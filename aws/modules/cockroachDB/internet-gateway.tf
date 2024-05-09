resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = local.tags
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  tags = local.tags
}

resource "aws_route" "this" {
  route_table_id = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.this.id
}