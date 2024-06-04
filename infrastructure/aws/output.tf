output "aws_ec2" {
  value = {
    instances = {
      hosts = zipmap([for ec2 in module.region.ec2s: ec2.name], [for ec2 in module.region.ec2s: {ansible_host: ec2.public_ip}])
    }
  }
}