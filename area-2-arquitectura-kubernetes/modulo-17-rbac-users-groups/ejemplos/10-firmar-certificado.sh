#!/bin/bash
# Script simplificado para firmar certificado existente
set -e

USERNAME=$1
CSR_FILE="${USERNAME}.csr"
CA_CERT=${2:-~/.minikube/ca.crt}
CA_KEY=${3:-~/.minikube/ca.key}

if [ -z "$USERNAME" ]; then
    echo "Uso: $0 <usuario> [ca.crt] [ca.key]"
    exit 1
fi

openssl x509 -req \
    -in ${CSR_FILE} \
    -CA ${CA_CERT} \
    -CAkey ${CA_KEY} \
    -CAcreateserial \
    -out ${USERNAME}.crt \
    -days 365

echo "✅ Certificado firmado: ${USERNAME}.crt"
