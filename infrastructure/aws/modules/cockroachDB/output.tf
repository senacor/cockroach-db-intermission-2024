output "ec2s" {
  value = [for index,ec2 in aws_instance.this: {
    name: "${data.aws_region.current.name}-${ec2.tags.Name}"
    public_ip : ec2.public_ip
    private_ip: ec2.private_ip
    zone: aws_subnet.subnets[index].availability_zone
    region: data.aws_region.current.name
  }]
}

output "load_balancer" {
  value = {
    dns_name: aws_lb.this.dns_name
  }
}