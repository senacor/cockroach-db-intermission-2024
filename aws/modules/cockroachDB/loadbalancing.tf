resource "aws_lb" "this" {
  name = "cockroach-db-load-balancer"
  internal = false
  load_balancer_type = "network"
  subnets = [for subnet in aws_subnet.subnets : subnet.id]
  security_groups = [aws_security_group.this.id]
  enable_cross_zone_load_balancing = true
  tags = local.tags
}

resource "aws_lb_target_group" "this" {
  name = "cockroach-db-nodes"
  port = 26257
  protocol = "tcp"
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

  tags = local.tags
}

resource "aws_lb_target_group_attachment" "this" {
  count = var.number_of_available_zones
  target_group_arn = aws_lb_target_group.this.arn
  target_id = aws_instance.this[count.index].id
  port = 26257
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port = 26257
  # Specify the port your instances are listening on
  protocol = "tcp"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = local.tags
}