# Prerequisitos - Lab 04: Estrategia Recreate

## Conocimientos Previos

- Laboratorio 1 (Crear Deployments) completado
- Laboratorio 2 (Rolling Updates) completado
- Laboratorio 3 (Rollback y Versiones) completado
- Conocimiento de Deployments y ReplicaSets
- Familiaridad con `kubectl apply` y manifiestos YAML

## Herramientas Necesarias

- Minikube o cluster Kubernetes funcional
- kubectl configurado y conectado al cluster
- Dos terminales disponibles (para monitoreo simultaneo)
- `diff` disponible en el sistema (incluido por defecto en Linux/macOS)
- `watch` disponible (incluido en Linux; en macOS instalar con `brew install watch`)

## Verificacion del Entorno

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
recreate-v1.yaml       rolling-compare-v1.yaml
recreate-v2.yaml       rolling-compare-v2.yaml
```

## Archivos YAML Incluidos

Este laboratorio incluye 4 archivos YAML organizados por pares (v1/v2) para cada ejercicio.
Cada archivo incluye:

- Comentario de uso (`# Uso: kubectl apply -f ...`)
- Descripcion de lo que hace el manifiesto
- Explicacion de la estrategia configurada
- Namespace declarado en el manifiesto (`lab-recreate`)

## Preparacion

```bash
# Crear namespace del laboratorio
kubectl create namespace lab-recreate
kubectl config set-context --current --namespace=lab-recreate

# Verificar
kubectl config view --minify | grep namespace:
```

**Output esperado**:
```
    namespace: lab-recreate
```

## Archivos del Laboratorio

| Archivo | Descripcion |
|---------|-------------|
| `recreate-v1.yaml` | Deployment inicial con Recreate (nginx:1.19) |
| `recreate-v2.yaml` | Actualizacion a nginx:1.20 via Recreate |
| `rolling-compare-v1.yaml` | Deployment comparativo RollingUpdate (nginx:1.19) |
| `rolling-compare-v2.yaml` | Actualizacion RollingUpdate a nginx:1.20 |
| `cleanup.sh` | Script de limpieza |

## Limpieza

```bash
./cleanup.sh
```
