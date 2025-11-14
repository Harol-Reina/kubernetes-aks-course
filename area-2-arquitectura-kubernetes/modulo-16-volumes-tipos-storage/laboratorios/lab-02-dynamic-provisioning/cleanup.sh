#!/bin/bash
echo "🧹 Limpiando Lab 02: Dynamic Provisioning..."
kubectl delete deployment app-dynamic-storage --ignore-not-found=true
kubectl delete pvc pvc-dynamic --ignore-not-found=true
kubectl delete sc fast-storage --ignore-not-found=true
echo "✅ Limpieza completada"
