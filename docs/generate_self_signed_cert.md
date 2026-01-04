## Generating Self Signed Certificate

1. Generate Root CA Private Key
```bash
openssl ecparam -name prime256v1 -genkey -noout -out ca.key
```

2. Generate the Root CA Certificate
```bash
openssl req -new -x509 -sha256 -key ca.key -out ca.crt -subj "/C=IN/ST=IN/L=IN /O=UIDAI /OU=UIDAI /CN=UIDAI /emailAddress=uidai@uidai.com"
```

3. Generate the Server Certificate Private Key
```bash
openssl ecparam -name prime256v1 -genkey -noout -out server.key
```