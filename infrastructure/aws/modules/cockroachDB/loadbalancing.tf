locals {
  ports = [26257, 8080]
  ports_map = {for index,value in local.ports: index => value }
  inverted_ports_map = {for key,value in local.ports_map: value => key }
}

resource "aws_lb" "this" {
  name = "cockroach-db-load-balancer"
  internal = false
  load_balancer_type = "network"
  subnets = [for subnet in aws_subnet.subnets : subnet.id]
  security_groups = [aws_security_group.this.id]
  enable_cross_zone_load_balancing = true
  tags = local.default_tags
}

resource "aws_lb_target_group" "this" {
  for_each = local.ports_map
  name = "cockroach-db-nodes"
  port = each.value
  protocol = "TCP"
  vpc_id = aws_vpc.this.id

  health_check {
    path = "/health?ready=1"
    port = 8080
    protocol = "HTTP"
    interval = 10
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 3
  }

  tags = local.default_tags
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = {
    for pair in setproduct([for index in range(var.number_of_available_zones): index], local.ports): "${pair[0]}.${pair[1]}" => {index: pair[0], port: pair[1]}
  }
  target_group_arn = aws_lb_target_group.this[local.inverted_ports_map[each.value.port]].arn
  target_id = aws_instance.this[tonumber(each.value.index)].id
  port = tonumber(each.value.port)
}

resource "aws_lb_listener" "this" {
  for_each = local.ports_map
  load_balancer_arn = aws_lb.this.arn
  port = each.value
  # Specify the port your instances are listening on
  protocol = "TCP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  tags = local.default_tags
}