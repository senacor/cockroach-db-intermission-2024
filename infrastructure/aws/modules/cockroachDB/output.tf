output "ec2s" {
  value = [for ec2 in aws_instance.this: {
    name: ec2.tags.Name
    public_ip : ec2.public_ip
    private_ip: ec2.private_ip
  }]
}