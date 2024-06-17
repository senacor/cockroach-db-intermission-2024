#!/bin/sh

cd infrastructure/aws
terraform apply
terraform output -json aws_ec2 > ../../hosts/aws_hosts.json
terraform output -json load_balancer > ../../hosts/load_balancer.json
cd ../../

cd certificate_generation
./generate_ca_certificates.sh
./generate_node_certificates.sh ../hosts/aws_hosts.json ../hosts/load_balancer.json
cd generated
CERTIFICATE_FOLDER="$(pwd)"
cd ../..
echo $CERTIFICATE_FOLDER

export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook setup/main.yml -i hosts/aws_hosts.json --key-file ~/aws_cockroach_db_ec2  -u ubuntu --extra-vars certificates_folder=$CERTIFICATE_FOLDER