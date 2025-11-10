#!/bin/bash
# Script para crear ConfigMaps desde literales

# Ejemplo 1: ConfigMap simple con variables de aplicación
kubectl create configmap app-config \
  --from-literal=database.host=postgres.default.svc.cluster.local \
  --from-literal=database.port=5432 \
  --from-literal=app.environment=production \
  --from-literal=app.log.level=info

echo "✅ ConfigMap 'app-config' creado"

# Ejemplo 2: ConfigMap para Redis
kubectl create configmap redis-config \
  --from-literal=redis.host=redis.default.svc.cluster.local \
  --from-literal=redis.port=6379 \
  --from-literal=redis.db=0 \
  --from-literal=redis.timeout=5000

echo "✅ ConfigMap 'redis-config' creado"

# Ejemplo 3: Feature flags
kubectl create configmap feature-flags \
  --from-literal=feature.cache.enabled=true \
  --from-literal=feature.analytics.enabled=true \
  --from-literal=feature.beta.enabled=false

echo "✅ ConfigMap 'feature-flags' creado"

# Ver los ConfigMaps creados
echo ""
echo "📋 ConfigMaps creados:"
kubectl get configmaps app-config redis-config feature-flags

# Ver contenido de uno
echo ""
echo "📄 Contenido de app-config:"
kubectl get configmap app-config -o yaml
