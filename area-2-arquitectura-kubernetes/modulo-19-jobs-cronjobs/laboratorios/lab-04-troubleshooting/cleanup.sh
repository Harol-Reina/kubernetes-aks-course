#!/bin/bash
echo "🧹 Limpiando Jobs y CronJobs..."
kubectl delete jobs --all -n default 2>/dev/null || true
kubectl delete cronjobs --all -n default 2>/dev/null || true
kubectl delete pods --all -n default 2>/dev/null || true
echo "✅ Limpieza completada"
