# Self-sign certificate demontration for jks and p12 
The following is the steps to create Key,Certificate and CSR:

## Keytool
### Generate JKS file
    > keytool -genkey -alias localhost_ssl -keyalg RSA -keysize 2048 -validity 700 -keypass secret -storepass secret -keystore server.jks
####    
    server:
      port: 443
      servlet:
        context-path: /
      ssl:
        enabled: true
        key-alias: local_ssl
        key-store: classpath:server.jks
        key-store-type: jks
        key-password: secret
        key-store-password: secret

### PKCS12
    > keytool -genkeypair -alias local_ssl -keyalg RSA -keysize 2048 -storetype PKCS12 -keystore local-ssl.p12 -validity 365 -ext san=dns:localhost
### Self sign Certificate
    > keytool -export -keystore local-ssl.p12 -alias local_ssl -file local-cert.crt
### CRT -> PEM conversion
    > openssl x509 -in cert.crt -out cert.pem
####
    server:
      port: 443
      servlet:
        context-path: /
      ssl:
        enabled: true
        key-alias: local_ssl
        key-store: classpath:local-ssl.p12
        key-store-type: PKCS12
        key-password: abcd123
        key-store-password: abcd123

## OpenSSL
### Private key
    > openssl genrsa -out private.key 2048
### CSR File
    > openssl req -new -key private.key -out localcsr.csr
### CRT File
    > openssl x509 -in localcsr.csr -out localcrt.crt -req -signkey private.key -days 365 -extfile v3.ext
### P12
    > openssl pkcs12 -export -out localp12.p12 -inkey private.key -in localcrt.crt
####
    server:
      port: 443
      servlet:
        context-path: /
      ssl:
        enabled: true
        key-alias: local_ssl
        key-store: classpath:localp12.p12
        key-store-type: PKCS12
        key-password: abcd123
        key-store-password: abcd123

## ext file

    subjectKeyIdentifier   = hash
    authorityKeyIdentifier = keyid:always,issuer:always
    basicConstraints       = CA:TRUE
    keyUsage               = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment, keyAgreement, keyCertSign
    subjectAltName         = @alt_names
    issuerAltName          = issuer:copy
    [alt_names]
    DNS.1 = localhost
    IP.1= 127.0.0.1

## Curl cmd for handshake
    > curl -v --key private.key --pass abcd123 https://localhost:443/hello


## Generating Root Certificates
Steps to generate a self-signed root certificate. We will use it for signing client and server certificates later in the story.
1.	This command generates a private key for the root certificate.
       
    > openssl genrsa -out rootCA.key 2048
2.	Request a certificate from openssl using the key generated in the previous step
      
    > openssl req -x509 -new -key rootCA.key -sha256 -days 365 -out rootCA.pem
      
### Signing Server Certificate
3.	Let’s create a private key and then a CSR for our server certificate.
      
    > openssl genrsa -out server.key 2048
4.	Now request a CSR with the key as input key:
      
    > openssl req -new -sha256 -key server.key -out server.csr
5.	let’s sign the server certificate with the given CSR.

    > openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out server.pem -days 365 -sha256

### Signing Client Certificate
As mentioned in the background, mutual TLS is based on both parties authenticating each other. If it were to be one-way TLS, we would not need the client certificate, because server would not request it. In this case however, we’d like the client to present its certificate and we’d like the server to authenticate it.

6.  Let’s create client certificates so we can use them to call the API. 

    > openssl genrsa -out client.key 2048

7.	Then create a CSR for the client in the same way
      
    > openssl req -new -sha256 -key client.key -out client.csr
8.	Then we sign the client certificate also in the same way
      
    > openssl x509 -req -in client.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out client.pem -days 365 -sha256

### Create keystore from server certificate
9.	Navigate to the directory where you have the certificates and run the following command to create a key store from server certificate and its private key.
      
    > openssl pkcs12 -export -in server.pem -out keystore.p12 -name server -inkey server.key
     
    > keytool -import -file rootCA.pem -alias rootCA -keystore truststore.p12 -storepass abc123
