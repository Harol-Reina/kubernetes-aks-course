#!/bin/bash
# ========================================================
# Script: Generar certificado de usuario para Kubernetes
# ========================================================
#
# Este script automatiza la creación de certificados de usuario
# firmados por el CA del cluster de Kubernetes.
#
# Uso: ./09-generar-usuario-certificado.sh [USUARIO] [GRUPO]
# Ejemplo: ./09-generar-usuario-certificado.sh maria developers
#
# ========================================================

set -e  # Salir si hay error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Parámetros
USERNAME=${1:-maria}
GROUP=${2:-developers}

print_info "Generando certificado para usuario: ${USERNAME}"
print_info "Grupo: ${GROUP}"

# Verificar que OpenSSL está instalado
if ! command -v openssl &> /dev/null; then
    print_error "OpenSSL no está instalado"
    exit 1
fi

# 1. Generar clave privada del usuario
print_info "Paso 1: Generando clave privada..."
openssl genrsa -out ${USERNAME}.key 2048

if [ $? -eq 0 ]; then
    print_info "✅ Clave privada creada: ${USERNAME}.key"
    chmod 600 ${USERNAME}.key  # Permisos restrictivos
else
    print_error "Error al generar clave privada"
    exit 1
fi

# 2. Crear Certificate Signing Request (CSR)
print_info "Paso 2: Creando Certificate Signing Request..."
openssl req -new \
    -key ${USERNAME}.key \
    -out ${USERNAME}.csr \
    -subj "/CN=${USERNAME}/O=${GROUP}"

if [ $? -eq 0 ]; then
    print_info "✅ CSR creado: ${USERNAME}.csr"
    print_info "   CN (Common Name): ${USERNAME}"
    print_info "   O (Organization): ${GROUP}"
else
    print_error "Error al crear CSR"
    exit 1
fi

# 3. Detectar ubicación del CA de Kubernetes
print_info "Paso 3: Buscando CA del cluster..."

# Intentar diferentes ubicaciones
if [ -f ~/.minikube/ca.crt ] && [ -f ~/.minikube/ca.key ]; then
    CA_CERT=~/.minikube/ca.crt
    CA_KEY=~/.minikube/ca.key
    print_info "✅ CA encontrado (minikube)"
elif [ -f /etc/kubernetes/pki/ca.crt ] && [ -f /etc/kubernetes/pki/ca.key ]; then
    CA_CERT=/etc/kubernetes/pki/ca.crt
    CA_KEY=/etc/kubernetes/pki/ca.key
    print_info "✅ CA encontrado (/etc/kubernetes/pki)"
else
    print_warning "CA no encontrado automáticamente"
    print_info "Ubicaciones intentadas:"
    print_info "  - ~/.minikube/ca.crt"
    print_info "  - /etc/kubernetes/pki/ca.crt"
    echo
    read -p "Ingrese ruta al CA cert: " CA_CERT
    read -p "Ingrese ruta al CA key: " CA_KEY
    
    if [ ! -f "$CA_CERT" ] || [ ! -f "$CA_KEY" ]; then
        print_error "Archivos de CA no válidos"
        exit 1
    fi
fi

# 4. Firmar el CSR con el CA del cluster
print_info "Paso 4: Firmando certificado con CA..."
openssl x509 -req \
    -in ${USERNAME}.csr \
    -CA ${CA_CERT} \
    -CAkey ${CA_KEY} \
    -CAcreateserial \
    -out ${USERNAME}.crt \
    -days 365

if [ $? -eq 0 ]; then
    print_info "✅ Certificado firmado: ${USERNAME}.crt (válido 365 días)"
else
    print_error "Error al firmar certificado"
    exit 1
fi

# 5. Verificar el certificado
print_info "Paso 5: Verificando certificado..."
CERT_SUBJECT=$(openssl x509 -in ${USERNAME}.crt -noout -subject)
print_info "Subject: ${CERT_SUBJECT}"

# Verificar que CN y O coinciden
if echo "$CERT_SUBJECT" | grep -q "CN = ${USERNAME}"; then
    print_info "✅ Usuario (CN) correcto: ${USERNAME}"
else
    print_warning "CN no coincide con usuario esperado"
fi

if echo "$CERT_SUBJECT" | grep -q "O = ${GROUP}"; then
    print_info "✅ Grupo (O) correcto: ${GROUP}"
else
    print_warning "O no coincide con grupo esperado"
fi

# 6. Resumen
echo
print_info "========================================="
print_info "Certificado generado exitosamente"
print_info "========================================="
echo
print_info "Archivos generados:"
echo "   📄 ${USERNAME}.key - Clave privada (¡NO COMPARTIR!)"
echo "   📄 ${USERNAME}.csr - Certificate Signing Request"
echo "   📄 ${USERNAME}.crt - Certificado firmado"
echo
print_info "Información del certificado:"
echo "   👤 Usuario (CN):  ${USERNAME}"
echo "   👥 Grupo (O):     ${GROUP}"
echo "   📅 Validez:       365 días"
echo
print_info "Próximos pasos:"
echo "   1. Configurar kubectl con estas credenciales:"
echo "      ./11-configurar-kubectl.sh ${USERNAME}"
echo
echo "   2. Crear Role y RoleBinding en Kubernetes:"
echo "      kubectl apply -f 01-role-pod-reader.yaml"
echo "      kubectl apply -f 03-rolebinding-basic.yaml"
echo
echo "   3. Probar permisos:"
echo "      kubectl auth can-i get pods --as ${USERNAME}"
echo
print_warning "⚠️  IMPORTANTE: Guarda ${USERNAME}.key de forma segura"
print_warning "⚠️  NO compartas la clave privada con nadie"

# Limpieza opcional del CSR (ya no es necesario)
read -p "¿Eliminar CSR (${USERNAME}.csr)? [s/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    rm ${USERNAME}.csr
    print_info "CSR eliminado"
fi
