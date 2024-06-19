output "aws_ec2" {
  value = {
    instances = {
      hosts = merge(
        zipmap([for ec2 in module.region_eu_central_1.ec2s: ec2.name], [for ec2 in module.region_eu_central_1.ec2s: {ansible_host: ec2.public_ip, load_balancer: module.region_eu_central_1.load_balancer.dns_name}]),
        zipmap([for ec2 in module.region_eu_west_1.ec2s: ec2.name], [for ec2 in module.region_eu_west_1.ec2s: {ansible_host: ec2.public_ip, load_balancer: module.region_eu_west_1.load_balancer.dns_name}])
      )
    }
  }
}