#!/bin/bash
# cert-monitor.sh - Monitorear y renovar certificados de Kubernetes

ALERT_DAYS=90
RENEW=false
EMAIL=""

# Procesar argumentos
while [ $# -gt 0 ]; do
    case $1 in
        --alert-days) ALERT_DAYS=$2; shift ;;
        --renew) RENEW=true ;;
        --email) EMAIL=$2; shift ;;
    esac
    shift
done

echo "🔐 Monitoreo de Certificados Kubernetes"
echo "========================================"
echo ""

# Verificar certificados
echo "📋 Estado de certificados:"
sudo kubeadm certs check-expiration

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Renovar si se solicita
if [ "$RENEW" = true ]; then
    echo "🔄 Renovando certificados..."
    sudo kubeadm certs renew all
    echo "✅ Certificados renovados"
    echo ""
    echo "⚠️  Recuerda reiniciar los componentes del control plane:"
    echo "   sudo systemctl restart kubelet"
    exit 0
fi

# Verificar expiración próxima
EXPIRING_SOON=$(sudo kubeadm certs check-expiration 2>/dev/null | grep -E "^[a-z]" | awk -v days=$ALERT_DAYS '$NF ~ /^[0-9]+d$/ && $NF+0 < days {print $1}')

if [ -n "$EXPIRING_SOON" ]; then
    echo "⚠️  ALERTA: Certificados próximos a expirar (<${ALERT_DAYS} días):"
    echo "$EXPIRING_SOON"
    
    if [ -n "$EMAIL" ]; then
        echo "📧 Enviando alerta a $EMAIL..."
        echo "Certificados próximos a expirar: $EXPIRING_SOON" | mail -s "⚠️  K8s Certs Alert" "$EMAIL"
    fi
    
    echo ""
    echo "💡 Ejecuta: sudo $0 --renew"
    exit 1
else
    echo "✅ Todos los certificados tienen más de $ALERT_DAYS días de validez"
    exit 0
fi
