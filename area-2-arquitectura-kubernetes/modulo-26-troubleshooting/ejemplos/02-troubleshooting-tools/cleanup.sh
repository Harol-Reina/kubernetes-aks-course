#!/bin/bash
# Cleanup troubleshooting tools

echo "🧹 Limpiando herramientas de troubleshooting..."

kubectl delete pod netshoot busybox dnsutils curl-pod alpine-pod ubuntu-pod \
  netshoot-hostnet privileged-debug python-debug nodejs-debug \
  --ignore-not-found

kubectl delete deployment debug-netshoot --ignore-not-found

echo "✅ Limpieza completada!"
