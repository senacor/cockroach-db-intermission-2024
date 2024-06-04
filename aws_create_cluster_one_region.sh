#!/bin/sh

cd infrastructure/aws
terraform apply
terraform output -json aws_ec2 > ../../hosts/aws_hosts.json
cd ../../
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook setup/main.yml -i hosts/aws_hosts.json --key-file $1 -u ubuntu