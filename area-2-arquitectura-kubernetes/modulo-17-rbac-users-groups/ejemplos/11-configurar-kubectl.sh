#!/bin/bash
# ========================================================
# Script: Configurar kubectl para nuevo usuario
# ========================================================
#
# Este script configura kubectl para usar el certificado
# de un usuario creado con el script 09.
#
# Uso: ./11-configurar-kubectl.sh [USUARIO] [NAMESPACE]
# Ejemplo: ./11-configurar-kubectl.sh maria development
#
# ========================================================

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${GREEN}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Parámetros
USERNAME=${1:-maria}
NAMESPACE=${2:-development}
CONTEXT_NAME="${USERNAME}-context"

print_info "Configurando kubectl para usuario: ${USERNAME}"

# Verificar que existen los archivos de certificado
if [ ! -f "${USERNAME}.crt" ] || [ ! -f "${USERNAME}.key" ]; then
    echo "❌ Certificados no encontrados: ${USERNAME}.crt y ${USERNAME}.key"
    echo "   Primero ejecuta: ./09-generar-usuario-certificado.sh ${USERNAME}"
    exit 1
fi

# Obtener información del cluster actual
CURRENT_CLUSTER=$(kubectl config view -o jsonpath='{.current-context}' | xargs kubectl config view -o jsonpath='{.contexts[?(@.name == "'"$(kubectl config current-context)"'")].context.cluster}')
API_SERVER=$(kubectl config view -o jsonpath='{.clusters[?(@.name == "'"${CURRENT_CLUSTER}"'")].cluster.server}')

print_info "Cluster: ${CURRENT_CLUSTER}"
print_info "API Server: ${API_SERVER}"

# 1. Set cluster (reutiliza el cluster actual)
print_info "Paso 1: Configurando cluster..."
kubectl config set-cluster ${CURRENT_CLUSTER} \
    --server=${API_SERVER} \
    --certificate-authority=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority}' | sed 's/^//' ) \
    --embed-certs=false

# 2. Set credentials
print_info "Paso 2: Configurando credenciales de usuario..."
kubectl config set-credentials ${USERNAME} \
    --client-certificate=${USERNAME}.crt \
    --client-key=${USERNAME}.key \
    --embed-certs=false

print_info "✅ Credenciales configuradas para ${USERNAME}"

# 3. Create context
print_info "Paso 3: Creando contexto..."
kubectl config set-context ${CONTEXT_NAME} \
    --cluster=${CURRENT_CLUSTER} \
    --user=${USERNAME} \
    --namespace=${NAMESPACE}

print_info "✅ Contexto creado: ${CONTEXT_NAME}"

# 4. Opcionalmente cambiar al nuevo contexto
echo
read -p "¿Cambiar al contexto '${CONTEXT_NAME}' ahora? [s/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    kubectl config use-context ${CONTEXT_NAME}
    print_info "✅ Contexto activo: ${CONTEXT_NAME}"
fi

# Resumen
echo
print_info "========================================="
print_info "kubectl configurado exitosamente"
print_info "========================================="
echo
echo "📋 Configuración:"
echo "   Usuario:    ${USERNAME}"
echo "   Cluster:    ${CURRENT_CLUSTER}"
echo "   Namespace:  ${NAMESPACE}"
echo "   Contexto:   ${CONTEXT_NAME}"
echo
echo "🔧 Comandos útiles:"
echo "   # Cambiar a contexto del usuario:"
echo "   kubectl config use-context ${CONTEXT_NAME}"
echo
echo "   # Ver contexto actual:"
echo "   kubectl config current-context"
echo
echo "   # Listar todos los contextos:"
echo "   kubectl config get-contexts"
echo
echo "   # Volver al contexto anterior:"
echo "   kubectl config use-context ${CURRENT_CLUSTER}"
echo
print_warning "⚠️  Recuerda: El usuario necesita Roles y RoleBindings"
echo "   para tener permisos en el cluster."
echo
echo "   Aplica los recursos RBAC:"
echo "   kubectl apply -f 01-role-pod-reader.yaml"
echo "   kubectl apply -f 03-rolebinding-basic.yaml"
