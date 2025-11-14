#!/bin/bash
# safe-drain.sh - Drenar nodo de forma segura

set -e

NODE=$1
GRACE_PERIOD=120
TIMEOUT=300
FORCE=false
DRY_RUN=false

# Procesar argumentos
shift
while [ $# -gt 0 ]; do
    case $1 in
        --grace-period) GRACE_PERIOD=$2; shift ;;
        --timeout) TIMEOUT=$2; shift ;;
        --force) FORCE=true ;;
        --dry-run) DRY_RUN=true ;;
    esac
    shift
done

if [ -z "$NODE" ]; then
    echo "Uso: $0 <node> [--grace-period 120] [--timeout 300] [--force] [--dry-run]"
    exit 1
fi

echo "🚧 Drenando nodo: $NODE"
echo "======================"
echo "Grace period: ${GRACE_PERIOD}s"
echo "Timeout: ${TIMEOUT}s"
echo ""

# Verificar nodo existe
if ! kubectl get node "$NODE" &> /dev/null; then
    echo "❌ Nodo $NODE no encontrado"
    exit 1
fi

# Dry run
if [ "$DRY_RUN" = true ]; then
    echo "🔍 Modo DRY-RUN (simulación)"
    kubectl drain "$NODE" --dry-run=client --ignore-daemonsets --delete-emptydir-data
    exit 0
fi

# Cordon node
echo "1️⃣  Marcando nodo como no programable..."
kubectl cordon "$NODE"

# Drain
echo "2️⃣  Drenando pods..."
DRAIN_CMD="kubectl drain $NODE --ignore-daemonsets --delete-emptydir-data --grace-period=$GRACE_PERIOD --timeout=${TIMEOUT}s"

if [ "$FORCE" = true ]; then
    DRAIN_CMD="$DRAIN_CMD --force"
fi

if $DRAIN_CMD; then
    echo "✅ Nodo $NODE drenado exitosamente"
    echo ""
    echo "⚠️  Recuerda ejecutar 'kubectl uncordon $NODE' después del mantenimiento"
else
    echo "❌ Error al drenar nodo"
    exit 1
fi
