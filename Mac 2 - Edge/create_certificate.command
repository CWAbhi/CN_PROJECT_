#!/bin/zsh
set -e
cd "$(dirname "$0")"
DOMAIN="$(sed -n 's/^DOMAIN=\([^ #]*\).*/\1/p' settings.env)"
if [[ -z "$DOMAIN" || "$DOMAIN" != *.test ]]; then
  echo "Set a .test DOMAIN in settings.env first."
  exit 1
fi
mkdir -p certs
if [[ -e certs/local-ca.key || -e certs/server.key ]]; then
  echo "Certificate files already exist. Move/backup them before regenerating."
  exit 1
fi
umask 077
openssl genrsa -out certs/local-ca.key 2048
cat > certs/ca.cnf <<EOF
[req]
distinguished_name=dn
x509_extensions=v3_ca
prompt=no
[dn]
CN=CN Project Phase 1 Local CA
[v3_ca]
basicConstraints=critical,CA:TRUE
keyUsage=critical,keyCertSign,cRLSign
subjectKeyIdentifier=hash
EOF
openssl req -x509 -new -sha256 -days 365 -key certs/local-ca.key -out certs/local-ca.crt -config certs/ca.cnf
openssl genrsa -out certs/server.key 2048
openssl req -new -key certs/server.key -out certs/server.csr -subj "/CN=app.$DOMAIN"
cat > certs/server.ext <<EOF
basicConstraints=critical,CA:FALSE
subjectAltName=DNS:app.$DOMAIN,DNS:api.$DOMAIN
extendedKeyUsage=serverAuth
keyUsage=digitalSignature,keyEncipherment
EOF
openssl x509 -req -in certs/server.csr -CA certs/local-ca.crt -CAkey certs/local-ca.key -CAcreateserial -out certs/server.crt -days 365 -sha256 -extfile certs/server.ext
echo "Created certs/server.crt, certs/server.key and certs/local-ca.crt."
echo "Copy only local-ca.crt to client Macs; keep local-ca.key private on Mac 2."
