#!/bin/bash
echo "🧹 Limpiando Lab 03: StatefulSet Storage..."
kubectl delete statefulset web-stateful --ignore-not-found=true
kubectl delete service web --ignore-not-found=true
kubectl delete pvc data-web-stateful-0 data-web-stateful-1 data-web-stateful-2 --ignore-not-found=true
echo "✅ Limpieza completada"
