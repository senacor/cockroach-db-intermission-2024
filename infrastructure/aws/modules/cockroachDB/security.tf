resource "aws_security_group" "this" {
  vpc_id = aws_vpc.this.id
  name = "cockroach_db_group"
  description = "Allow inbound traffic and outbound traffic for a cockroach db node"

  tags = local.default_tags
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 22
  to_port = 22
  ip_protocol = "TCP"
  tags = local.default_tags
}

resource "aws_vpc_security_group_ingress_rule" "inter_node_communication" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4 = aws_vpc.this.cidr_block
  from_port = 26257
  to_port = 26257
  ip_protocol = "TCP"
  tags = local.default_tags
}

resource "aws_vpc_security_group_egress_rule" "inter_node_communication" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4 = aws_vpc.this.cidr_block
  from_port = 26257
  to_port = 26257
  ip_protocol = "TCP"
  tags = local.default_tags
}

resource "aws_vpc_security_group_ingress_rule" "db_console" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4 = aws_vpc.this.cidr_block
  from_port = 8080
  to_port = 8080
  ip_protocol = "TCP"
  tags = local.default_tags
}

resource "aws_vpc_security_group_egress_rule" "db_console" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4 = aws_vpc.this.cidr_block
  from_port = 8080
  to_port = 8080
  ip_protocol = "TCP"
  tags = local.default_tags
}