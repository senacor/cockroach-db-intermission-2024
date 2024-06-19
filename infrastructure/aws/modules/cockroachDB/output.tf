output "ec2s" {
  value = [for ec2 in aws_instance.this: {
    name: "${data.aws_region.current.name}-${ec2.tags.Name}"
    public_ip : ec2.public_ip
    private_ip: ec2.private_ip
  }]
}

output "load_balancer" {
  value = {
    dns_name: aws_lb.this.dns_name
  }
}