#!/bin/bash

# cleanup.sh - Lab 01: Helm Basics

echo "🧹 Limpiando recursos del Lab 01: Helm Basics..."

# Listar releases actuales
echo "Releases instalados:"
helm list

# Desinstalar releases del lab
echo ""
echo "Eliminando releases..."
helm uninstall mi-nginx 2>/dev/null || echo "  - mi-nginx no existe"
helm uninstall mi-chart 2>/dev/null || echo "  - mi-chart no existe"
helm uninstall wordpress 2>/dev/null || echo "  - wordpress no existe"

# Limpiar namespace del lab si existe
read -p "¿Eliminar namespace 'helm-lab' si existe? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    kubectl delete namespace helm-lab 2>/dev/null && echo "✅ Namespace eliminado" || echo "  - Namespace no existe"
fi

# Limpiar charts descargados localmente
if [ -d "my-chart" ]; then
    read -p "¿Eliminar directorio 'my-chart' creado en el lab? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        rm -rf my-chart && echo "✅ Directorio my-chart eliminado"
    fi
fi

echo ""
echo "✅ Limpieza completada"
echo ""
echo "Verificando estado final..."
helm list || echo "✓ No hay releases activos"
kubectl get all -n helm-lab 2>/dev/null || echo "✓ Namespace helm-lab limpio o eliminado"
