output "aws_ec2" {
  value = {
    instances = {
      hosts = merge(
      zipmap([for ec2 in module.first_region.ec2s: ec2.name], [for ec2 in module.first_region.ec2s: {
        ansible_host: ec2.public_ip,
        load_balancer: module.first_region.load_balancer.dns_name,
        ansible_user: "ubuntu",
        cloud: "aws",
        region : ec2.region,
        zone: ec2.zone
      }]),
      zipmap([for ec2 in module.second_region.ec2s: ec2.name], [for ec2 in module.second_region.ec2s: {
        ansible_host: ec2.public_ip,
        load_balancer: module.second_region.load_balancer.dns_name,
        ansible_user: "ubuntu",
        cloud: "aws",
        region : ec2.region,
        zone: ec2.zone
      }])
      )
    }
  }
}