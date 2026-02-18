#!/bin/bash

# cleanup.sh - Lab 01: Azure VM

echo "🧹 Limpiando recursos de Azure VM..."
echo ""
echo "⚠️  Este script NO elimina recursos automáticamente"
echo "Debes eliminar la VM manualmente desde Azure Portal o CLI"
echo ""
echo "Opciones de limpieza:"
echo ""
echo "1️⃣  Azure Portal:"
echo "   - Ir a portal.azure.com"
echo "   - Buscar 'Resource Groups'"
echo "   - Seleccionar tu resource group (ej: rg-docker-course)"
echo "   - Click 'Delete resource group'"
echo "   - Escribir nombre del resource group para confirmar"
echo "   - Click 'Delete'"
echo ""
echo "2️⃣  Azure CLI (si está instalado):"
echo "   az group delete --name rg-docker-course --yes --no-wait"
echo ""
echo "3️⃣  Verificar eliminación:"
echo "   az group list --output table"
echo ""
echo "💰 IMPORTANTE: Eliminar el resource group completo elimina:"
echo "   - VM"
echo "   - Disco"
echo "   - Red virtual"
echo "   - IP pública"
echo "   - Network security group"
echo "   Todo de una vez y evita cargos."
echo ""
read -p "¿Ya eliminaste los recursos de Azure? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo "✅ Perfecto! Lab completado y limpio."
else
    echo "⚠️  Recuerda eliminar los recursos para evitar cargos."
    echo "Usa los métodos mostrados arriba."
fi
