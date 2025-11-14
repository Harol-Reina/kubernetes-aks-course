#!/bin/bash
# upgrade-cluster.sh - Actualizar versión de Kubernetes del cluster

set -e

VERSION=$1
DRY_RUN=false
SKIP_BACKUP=false

# Procesar argumentos
for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=true ;;
        --skip-backup) SKIP_BACKUP=true ;;
    esac
done

if [ -z "$VERSION" ]; then
    echo "Uso: $0 <version> [--dry-run] [--skip-backup]"
    echo "Ejemplo: $0 1.28.4"
    exit 1
fi

echo "🚀 Actualización de cluster a Kubernetes $VERSION"
echo "=================================================="
echo ""

# Verificar kubeadm
if ! command -v kubeadm &> /dev/null; then
    echo "❌ kubeadm no encontrado"
    exit 1
fi

# Dry run
if [ "$DRY_RUN" = true ]; then
    echo "🔍 Modo DRY-RUN (simulación)"
    sudo kubeadm upgrade plan v$VERSION
    exit 0
fi

# Backup etcd (si no se salta)
if [ "$SKIP_BACKUP" = false ]; then
    echo "💾 Creando backup de etcd..."
    ETCDCTL_API=3 etcdctl snapshot save /var/backups/etcd-backup-$(date +%Y%m%d-%H%M%S).db \
        --endpoints=https://127.0.0.1:2379 \
        --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/server.crt \
        --key=/etc/kubernetes/pki/etcd/server.key
    echo "✅ Backup creado"
fi

# Upgrade control plane
echo ""
echo "⬆️  Actualizando control plane..."
sudo kubeadm upgrade apply v$VERSION -y

echo ""
echo "✅ Control plane actualizado a v$VERSION"
echo ""
echo "⚠️  Recuerda actualizar kubelet y kubectl en todos los nodos:"
echo "   sudo apt-get update && sudo apt-get install -y kubelet=$VERSION-00 kubectl=$VERSION-00"
echo "   sudo systemctl daemon-reload && sudo systemctl restart kubelet"
