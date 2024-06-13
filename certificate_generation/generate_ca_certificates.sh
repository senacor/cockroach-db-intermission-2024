#!/bin/bash

source helper.sh

createDirectory $BASE_DIR

cd $BASE_DIR

createDirectory "$CA_DIR"
createPrivateKey "$CA_DIR/$CA_PRIVATE_KEY_NAME"

#Create the CA certificate

openssl req \
-new \
-x509 \
-config ../ca.cnf \
-key $CA_DIR/$CA_PRIVATE_KEY_NAME \
-out $CA_DIR/$CA_CERT_NAME \
-days 365 \
-batch

rm -f index.txt serial.txt
touch index.txt
echo '01' > serial.txt

cd ..