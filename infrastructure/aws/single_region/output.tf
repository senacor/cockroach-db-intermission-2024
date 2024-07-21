output "aws_ec2" {
  value = {
    instances = {
      hosts = zipmap([for ec2 in module.region.ec2s: ec2.name], [for ec2 in module.region.ec2s: {
        ansible_host: ec2.public_ip, load_balancer: module.region.load_balancer.dns_name, ansible_user: "ubuntu",
        cloud: "aws", region : ec2.region, zone: ec2.zone
      }])
    }
  }
}