#!/bin/bash
# Pre-flight check for Lab 04

echo "🔍 Verificando prerrequisitos para Lab 04..."
echo ""

# Check cluster accessibility
echo "1. Verificando acceso al cluster..."
if kubectl get nodes &>/dev/null; then
  echo "   ✅ Cluster accesible"
else
  echo "   ❌ No se puede acceder al cluster"
  exit 1
fi

# Check nodes
echo "2. Verificando nodes..."
NODES=$(kubectl get nodes --no-headers | wc -l)
if [ "$NODES" -ge 2 ]; then
  echo "   ✅ Cluster multi-node ($NODES nodes)"
else
  echo "   ⚠️  Solo 1 node - algunos escenarios no aplicarán"
fi

# Check control plane access
echo "3. Verificando acceso a control plane..."
if sudo ls /etc/kubernetes/manifests/ &>/dev/null; then
  echo "   ✅ Acceso a control plane"
else
  echo "   ❌ No hay acceso a /etc/kubernetes/manifests/"
  echo "      Ejecuta este script en el control plane node"
  exit 1
fi

# Check etcd
echo "4. Verificando etcd..."
if sudo crictl ps | grep -q etcd; then
  echo "   ✅ etcd corriendo"
else
  echo "   ❌ etcd no encontrado"
fi

# Check backup directory
echo "5. Verificando directorio de backup..."
if sudo mkdir -p /backup/etcd &>/dev/null; then
  echo "   ✅ Directorio /backup/etcd creado"
else
  echo "   ❌ No se puede crear /backup/etcd"
fi

# Check sudo access
echo "6. Verificando permisos sudo..."
if sudo -v &>/dev/null; then
  echo "   ✅ Sudo acceso disponible"
else
  echo "   ❌ Se requiere sudo"
  exit 1
fi

echo ""
echo "✅ Todos los prerrequisitos cumplidos!"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   - Este lab SOLO debe ejecutarse en clusters de prueba"
echo "   - Creará situaciones de fallo crítico"
echo "   - Ten un backup antes de continuar"
echo ""
echo "Continuar con: ./create-backup.sh"
