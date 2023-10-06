#!/bin/bash

ca_key_bits="2048"
validity_days="365"

echo "Starting Root certificate"
openssl genrsa -out rootCA.key "$ca_key_bits"
openssl req -new -key rootCA.key -out rootCSR.csr -subj "//C=GB\ST=London\L=London\O=Global Security\OU=IT Department\CN=localhost"
openssl req -x509 -in rootCSR.csr -key rootCA.key -sha256 -days "$validity_days" -out rootCA.pem
openssl x509 -in rootCSR.csr -out rootCRT.crt -req -signkey rootCA.key -days "$validity_days" -extfile v3.ext

echo "Starting Signing Server certificate"
openssl genrsa -out server.key "$ca_key_bits"
openssl req -new -sha256 -key server.key -out server.csr -subj "//C=GB\ST=London\L=London\O=Global Security\OU=IT Department\CN=localhost"
openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out server.pem -days "$validity_days" -sha256

echo "Starting Signing Client certificate"
openssl genrsa -out client.key "$ca_key_bits"
openssl req -new -sha256 -key client.key -out client.csr -subj "//C=GB\ST=London\L=London\O=Global Security\OU=IT Department\CN=localhost"
openssl x509 -req -in client.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out client.pem -days "$validity_days" -sha256
openssl x509 -in client.csr -out client.crt -req -signkey client.key -days "$validity_days" -extfile v3.ext

echo "Starting to create a key store from server certificate "
openssl pkcs12 -export -in server.pem -out keystore.p12 -name server -inkey server.key -passout pass:abc1234
keytool -import -file rootCA.pem -alias rootCA -keystore truststore.p12 -storepass abc1234