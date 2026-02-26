# Prerequisitos - Lab 02: Rolling Updates y Estrategias de Despliegue

## Conocimientos Previos

- ✅ Laboratorio 1 (Crear Deployments) completado
- ✅ Conocimiento de Deployments y ReplicaSets
- ✅ Familiaridad con `kubectl apply` y manifiestos YAML

## Herramientas Necesarias

- ✅ Minikube o cluster Kubernetes funcional
- ✅ kubectl configurado y conectado al cluster
- ✅ Dos terminales disponibles (para monitoreo simultáneo)
- ✅ `diff` disponible en el sistema (incluido por defecto en Linux/macOS)

## Verificación del Entorno

```bash
# Verificar cluster activo
kubectl cluster-info

# Verificar Deployments y ReplicaSets funcionan
kubectl get deployments
kubectl get rs

# Verificar que puedes crear namespaces
kubectl auth can-i create namespaces

# Verificar archivos YAML del laboratorio
ls -la *.yaml
```

**Output esperado**:
```
rolling-demo-v1.yaml     rolling-ha-v1.yaml     rolling-fast-v1.yaml
rolling-demo-v2.yaml     rolling-ha-v2.yaml     rolling-fast-v2.yaml
recreate-demo-v1.yaml    pause-demo-v1.yaml     challenge-app-v1.yaml
recreate-demo-v2.yaml    pause-demo-v2.yaml     challenge-app-v2.yaml
```

## Archivos YAML Incluidos

Este laboratorio incluye 12 archivos YAML organizados por pares (v1/v2) para cada ejercicio. Cada archivo incluye:

- Comentario de uso (`# Uso: kubectl apply -f ...`)
- Descripción de lo que hace el manifiesto
- Explicación de los cambios respecto a la versión anterior (en archivos v2)
- Namespace declarado en el manifiesto (`lab-rolling-updates`)
