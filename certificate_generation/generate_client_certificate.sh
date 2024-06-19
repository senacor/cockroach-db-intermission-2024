#!/bin/bash

## Usage: generate_node_certificates.sh NAME_OF_THE_HOST_FILE NAME_OF_THE_LOAD_BALANCER_FILE
source helper.sh

createClientConfig() {
  CONFIG_FILE=client.cnf
  if [ -f "$CONFIG_FILE" ]; then
    echo "$CONFIG_FILE exists! Remove it!"
    rm -r $CONFIG_FILE
  fi
  echo "[ req ]" >>$CONFIG_FILE
  echo "prompt=no" >>$CONFIG_FILE
  echo "distinguished_name = distinguished_name" >>$CONFIG_FILE
  echo "[ distinguished_name ]" >>$CONFIG_FILE
  echo "organizationName = Cockroach" >>$CONFIG_FILE
  echo "commonName = $1" >>$CONFIG_FILE
}

createCert() {
  local NAME=$1
  echo "username: $NAME"
  local CLIENT_DIR="$CLIENTS_BASE_DIR/$NAME"
  setClientName $1
  local CLIENT_PRIVATE_KEY_NAME="$CLIENT_NAME.key"
  local CLIENT_CERT_NAME="$CLIENT_NAME.crt"
  local CLIENT_SIGNING_REQUEST_NAME="$CLIENT_NAME.csr"
  createDirectory "$CLIENT_DIR"
  cd "$CLIENT_DIR"

  createClientConfig "$NAME"
  createPrivateKey "$CLIENT_PRIVATE_KEY_NAME"
  createDirectory "$CLIENT_CERT_DIR"

 echo "$(pwd)"
  openssl req \
    -new \
    -config $CONFIG_FILE \
    -key $CLIENT_PRIVATE_KEY_NAME \
    -out $CLIENT_SIGNING_REQUEST_NAME \
    -batch

  echo "openssl req \
            -new \
            -config $CONFIG_FILE \
            -key $CLIENT_PRIVATE_KEY_NAME \
            -out $CLIENT_SIGNING_REQUEST_NAME \
            -batch"
  cd ../..

  openssl ca \
    -config ../ca.cnf \
    -keyfile $CA_DIR/$CA_PRIVATE_KEY_NAME \
    -cert $CA_DIR/$CA_CERT_NAME \
    -policy signing_policy \
    -extensions signing_node_req \
    -out $CLIENT_DIR/$CLIENT_CERT_NAME -outdir $CLIENT_DIR/$CLIENT_CERT_DIR/ \
    -in $CLIENT_DIR/$CLIENT_SIGNING_REQUEST_NAME \
    -batch
}


# create certificate for each node
cd $BASE_DIR
createDirectory $CLIENTS_BASE_DIR
createCert $1
cd ..