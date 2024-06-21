#!/bin/sh

cd infrastructure/aws/multi_region
terraform apply
terraform output -json aws_ec2 > ../../../hosts/aws_hosts.json
cd ../../../

ROOT_USER=root
cd certificate_generation
./generate_ca_certificates.sh
./generate_client_certificate.sh $ROOT_USER
./generate_node_certificates.sh ../hosts/aws_hosts.json $ROOT_USER
cd generated
CERTIFICATE_FOLDER="$(pwd)"
cd ../..
echo $CERTIFICATE_FOLDER

export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook setup/main.yml -i hosts/aws_hosts.json --key-file ~/aws_cockroach_db_ec2 --extra-vars certificates_folder=$CERTIFICATE_FOLDER