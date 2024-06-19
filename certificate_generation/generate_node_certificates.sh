#!/bin/bash

## Usage: generate_node_certificates.sh NAME_OF_THE_HOST_FILE NAME_OF_THE_LOAD_BALANCER_FILE ROOT_USER
source helper.sh

createNodeConfig() {
  local CONFIG_FILE=node.cnf
  if [ -f "$CONFIG_FILE" ]; then
    echo "$CONFIG_FILE exists! Remove it!"
    rm -r $CONFIG_FILE
  fi
  echo "# OpenSSL node configuration file" >>$CONFIG_FILE
  echo "[ req ]" >>$CONFIG_FILE
  echo "prompt=no" >>$CONFIG_FILE
  echo "distinguished_name = distinguished_name" >>$CONFIG_FILE
  echo "req_extensions = extensions" >>$CONFIG_FILE
  echo "[ distinguished_name ]" >>$CONFIG_FILE
  echo "organizationName = Cockroach" >>$CONFIG_FILE
  echo "[ extensions ]" >>$CONFIG_FILE
  echo "subjectAltName = critical,IP:$1,DNS:node,DNS:localhost,IP:127.0.0.1,DNS:$LOAD_BALANCER_DNS_NAME" >>$CONFIG_FILE
}

createCert() {
  NAME=$1
  IP=$2
  ROOT_USER=$3
  echo "name: $NAME"
  echo "ip: $IP"
  echo "root_user: $ROOT_USER"
  NODE_DIR="$NAME"
  createDirectory "$NODE_DIR"
  cd "$NODE_DIR"

  createNodeConfig "$IP"
  createPrivateKey "$NODE_PRIVATE_KEY_NAME"
  createDirectory "$NODE_CERT_DIR"

  openssl req \
    -new \
    -config node.cnf \
    -key $NODE_PRIVATE_KEY_NAME \
    -out node.csr \
    -batch

  cd ..

  openssl ca \
    -config ../ca.cnf \
    -keyfile $CA_DIR/$CA_PRIVATE_KEY_NAME \
    -cert $CA_DIR/$CA_CERT_NAME \
    -policy signing_policy \
    -extensions signing_node_req \
    -out $NODE_DIR/$NODE_CERT_NAME -outdir $NODE_DIR/$NODE_CERT_DIR/ \
    -in $NODE_DIR/node.csr \
    -batch

  setClientName $ROOT_USER
  local CLIENT_CERT_NAME="$CLIENT_NAME.crt"
  local CLIENT_PRIVATE_KEY_NAME="$CLIENT_NAME.key"

  cp "$CA_DIR/$CA_CERT_NAME" "$NODE_DIR/$CA_CERT_NAME"
  cp "$CLIENTS_BASE_DIR/$ROOT_USER/$CLIENT_CERT_NAME" "$NODE_DIR/$CLIENT_CERT_NAME"
  cp "$CLIENTS_BASE_DIR/$ROOT_USER/$CLIENT_PRIVATE_KEY_NAME" "$NODE_DIR/$CLIENT_PRIVATE_KEY_NAME"
}

createCerts() {
  for i in "${!HOSTS[@]}"; do
    NAME=$i
    IP="${HOSTS[$i]}"
    createCert $NAME $IP $1
  done
}

# extract hosts
declare -A HOSTS="($(jq -r '.instances.hosts | to_entries | .[] | @sh "[\(.key)]=\(.value.ansible_host)"' $1))"

#extract load balancer dns name
LOAD_BALANCER_DNS_NAME="$(jq -r '.dns_name' $2)"

# create certificate for each node
cd $BASE_DIR
createCerts $3
cd ..