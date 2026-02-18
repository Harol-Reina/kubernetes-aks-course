#!/bin/bash

# cleanup.sh - Lab 02: Multi-contenedor y Labels
# Limpia todos los recursos creados durante el laboratorio

echo "🧹 Limpiando recursos del Lab 02: Multi-contenedor y Labels..."

# Eliminar pods multi-contenedor
echo "Eliminando pods multi-contenedor..."
kubectl delete pod sidecar-pod 2>/dev/null || echo "  - sidecar-pod no existe"
kubectl delete pod ambassador-pod 2>/dev/null || echo "  - ambassador-pod no existe"
kubectl delete pod multi-container-pod 2>/dev/null || echo "  - multi-container-pod no existe"

# Eliminar pods por labels
echo "Eliminando pods por labels..."
kubectl delete pods -l app=multi-pod 2>/dev/null
kubectl delete pods -l tier=frontend 2>/dev/null
kubectl delete pods -l lab=lab-02-multi-contenedor 2>/dev/null

# Eliminar services si se crearon
echo "Eliminando services..."
kubectl delete svc frontend-service 2>/dev/null || echo "  - frontend-service no existe"
kubectl delete svc -l lab=lab-02-multi-contenedor 2>/dev/null

# Limpiar namespace dedicado si se creó
read -p "¿Eliminar namespace 'lab-multi-container' si existe? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    kubectl delete namespace lab-multi-container 2>/dev/null && echo "✅ Namespace eliminado" || echo "  - Namespace no existe"
fi

echo ""
echo "✅ Limpieza completada"
echo "Verificando estado final..."
kubectl get pods -l lab=gestion-pods 2>/dev/null || echo "✓ No quedan pods del lab"
kubectl get svc -l lab=gestion-pods 2>/dev/null || echo "✓ No quedan services del lab"
