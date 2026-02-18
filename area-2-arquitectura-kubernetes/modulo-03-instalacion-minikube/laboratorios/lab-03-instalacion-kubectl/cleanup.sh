#!/bin/bash
echo "🧹 Limpiando recursos..."
minikube delete 2>/dev/null || true
echo "✅ Limpieza completada"
