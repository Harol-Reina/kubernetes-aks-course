#!/bin/bash
echo "🧹 Limpiando Lab 01: PV/PVC Static..."
kubectl delete pod pod-with-pvc --ignore-not-found=true
kubectl delete pvc pvc-manual --ignore-not-found=true
kubectl delete pv pv-manual --ignore-not-found=true
echo "✅ Limpieza completada"
