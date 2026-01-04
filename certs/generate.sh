#!/usr/bin/env bash
set -e

DOMAIN=Kali

# 1. Root CA private key
openssl genrsa -out rootCA.key 4096

# 2. Root CA certificate
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt \
  -subj "/C=IN/O=KaliRootCA/CN=Kali Root CA"

# 3. Server private key
openssl genrsa -out ${DOMAIN}.key 2048

# 4. Create CSR with embedded values + SAN
openssl req -new -key ${DOMAIN}.key -out ${DOMAIN}.csr \
  -subj "/C=IN/O=KaliOrg/CN=${DOMAIN}" \
  -addext "subjectAltName=DNS:${DOMAIN},DNS:localhost,IP:127.0.0.1"

# 5. Sign CSR -> server certificate
openssl x509 -req -in ${DOMAIN}.csr \
  -CA rootCA.crt -CAkey rootCA.key -CAcreateserial \
  -out ${DOMAIN}.crt -days 825 -sha256 \
  -extfile <(printf "subjectAltName=DNS:${DOMAIN},DNS:localhost,IP:127.0.0.1\nextendedKeyUsage=serverAuth")

# 6. Verify
openssl verify -CAfile rootCA.crt ${DOMAIN}.crt