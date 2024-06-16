#!/bin/sh

cd infrastructure/aws
terraform apply
terraform output -json aws_ec2 > ../../hosts/aws_hosts.json
terraform output -json load_balancer > ../../hosts/load_balancer.json
cd ../../
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook setup/main.yml -i hosts/aws_hosts.json --key-file $1 -u ubuntu
#ansible-playbook setup/main.yml -i hosts/aws_hosts.json --key-file ~/aws_cockroach_db_ec2  -u ubuntu --extra-vars certificates_folder=ABSOLUTE_PATH