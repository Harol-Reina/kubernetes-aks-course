# Prerequisitos - Lab 03: Rollback y Gestión de Versiones

## Conocimientos Previos

- ✅ Laboratorios 1 y 2 completados
- ✅ Conocimiento de Deployments y rolling updates
- ✅ Familiaridad con `kubectl apply` y manifiestos YAML
- ✅ Comprensión de ReplicaSets y su relación con Deployments

## Herramientas Necesarias

- ✅ Minikube o cluster Kubernetes funcional
- ✅ kubectl configurado y conectado al cluster
- ✅ Dos terminales disponibles (para monitoreo simultáneo)
- ✅ `diff` disponible en el sistema (incluido por defecto en Linux/macOS)
- ✅ `jq` instalado (para formatear JSON en ejercicio 4)

## Verificación del Entorno

```bash
# Verificar cluster activo
kubectl cluster-info

# Verificar Deployments y ReplicaSets funcionan
kubectl get deployments
kubectl get rs

# Verificar jq instalado
jq --version

# Verificar que puedes crear namespaces
kubectl auth can-i create namespaces

# Verificar archivos YAML del laboratorio
ls -la *.yaml *.sh
```

**Output esperado** (archivos YAML):
```
version-history-v1.yaml    version-history-v4.yaml    production-app-v1.yaml
version-history-v2.yaml    version-history-v5.yaml    production-app-v2-broken.yaml
version-history-v3.yaml    version-history-v6.yaml    auto-rollback-v1.yaml
versioned-app-v1.yaml      versioned-app-v3.yaml      auto-rollback-v2-broken.yaml
versioned-app-v2.yaml      versioned-app-v4-broken.yaml
critical-service-v1.yaml   critical-service-v2-broken.yaml
cleanup.sh                 safe-rollback.sh
```

## Archivos del Laboratorio

Este laboratorio incluye 16 archivos YAML y 2 scripts organizados por ejercicio:

- **Ejercicio 1** (6 archivos): `version-history-v1.yaml` a `v6.yaml` — construcción de historial
- **Ejercicio 3** (2 archivos): `production-app-v1.yaml` y `v2-broken.yaml` — deploy fallido
- **Ejercicio 4** (2 archivos): `auto-rollback-v1.yaml` y `v2-broken.yaml` — progressDeadlineSeconds
- **Ejercicio 5** (4 archivos): `versioned-app-v1.yaml` a `v4-broken.yaml` — workflow completo
- **Desafío** (2 archivos): `critical-service-v1.yaml` y `v2-broken.yaml` — incidente producción
- **Scripts**: `safe-rollback.sh` (rollback automático), `cleanup.sh` (limpieza)

> Los archivos con sufijo `-broken` contienen imágenes inválidas que fallan intencionalmente.
