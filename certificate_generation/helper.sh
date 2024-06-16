#!/bin/bash

BASE_DIR=generated
CA_DIR=ca
CA_PRIVATE_KEY_NAME="ca.key"
CA_CERT_NAME="ca.crt"
NODE_PRIVATE_KEY_NAME="node.key"
NODE_CERT_NAME="node.crt"
NODE_CERT_DIR="certs"

#createDirectory DIRECTORY_TO_BE_CREATED
createDirectory() {
  if [ ! -d "$1" ]; then
    mkdir "$1"
  else
    echo "$1 exists! Remove all files in it!"
    rm -r $1/*
  fi
}

# createPrivateKey NAME_OF_PRIVATE_KEY
createPrivateKey(){
  #Create the CA key
  openssl genrsa -out $1 2048
  chmod 400 $1
}