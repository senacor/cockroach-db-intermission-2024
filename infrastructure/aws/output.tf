output "aws_ec2" {
  value = {
    ec2 = {
      hosts = zipmap([for ec2 in module.region.ec2s: ec2.name], [for ec2 in module.region.ec2s: ec2.public_ip])
    }
  }
}