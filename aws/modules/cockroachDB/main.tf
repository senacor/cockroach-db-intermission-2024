resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"

  tags = local.tags
}

locals {
  available_zones_suffixes = [
    "a",
    "b",
    "c",
    "d"]
  available_zones = [for index in range(var.number_of_available_zones): "${var.region}${local.available_zones_suffixes[index]}"]
  cidr_blocks = [for index, name  in local.available_zones : "10.0.${index + 1}.0/24"]
  tags = {
    project = "cockroach-intermission-2024"
  }
}

resource "aws_subnet" "subnets" {
  count = var.number_of_available_zones
  vpc_id = aws_vpc.this.id
  cidr_block = local.cidr_blocks[count.index]
  availability_zone = local.available_zones[count.index]
  tags = local.tags
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = [
      "hvm"]
  }

  owners = [
    "099720109477"]
  # Canonical's AWS account ID
}

resource "aws_instance" "this" {
  count = var.number_of_available_zones
  ami = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type
  subnet_id = aws_subnet.subnets[count.index].id
  vpc_security_group_ids = [
    aws_security_group.this.id]

  tags = local.tags
}

resource "aws_ebs_volume" "this" {
  count = var.number_of_available_zones
  availability_zone = local.available_zones[count.index]
  size = 4
  type = "gp2"

  tags = local.tags
}

resource "aws_volume_attachment" "this" {
  count = var.number_of_available_zones
  device_name = "/dev/sdf" //TODO
  # Device name to attach the volume to on the EC2 instance
  instance_id = aws_instance.this[count.index].id
  volume_id = aws_ebs_volume.this[count.index].id
}