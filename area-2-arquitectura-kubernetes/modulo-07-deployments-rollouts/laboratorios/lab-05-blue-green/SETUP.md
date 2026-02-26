# Prerequisitos - Lab 05: Estrategias Blue-Green y Canary

## Conocimientos Previos

- Laboratorio 1 (Crear Deployments) completado
- Laboratorio 2 (Rolling Updates) completado
- Conocimiento de Deployments, ReplicaSets y Services
- Familiaridad con `kubectl apply`, `kubectl patch` y `kubectl scale`
- Entender el concepto de label selectors en Services

## Herramientas Necesarias

- Minikube o cluster Kubernetes funcional
- kubectl configurado y conectado al cluster
- Dos terminales disponibles (para monitoreo simultaneo con `watch`)
- `curl` disponible en el sistema para pruebas de trafico

## Verificacion del Entorno

```bash
# Verificar cluster activo
kubectl cluster-info

# Verificar Deployments y Services funcionan
kubectl get deployments
kubectl get services

# Verificar que puedes crear namespaces
kubectl auth can-i create namespaces

# Verificar archivos YAML del laboratorio
ls -la *.yaml
```

**Output esperado de ls**:
```
app-canary-v2.yaml       canary-failing.yaml      service-canary.yaml
app-stable-v1.yaml       canary-with-health.yaml  service-green-test.yaml
blue-deployment.yaml     green-deployment.yaml    service-production.yaml
                         weighted-canary.yaml
```

## Archivos YAML Incluidos

Este laboratorio incluye 10 archivos YAML organizados por estrategia y ejercicio:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `blue-deployment.yaml` | Ejercicio 1 | Version Blue activa en produccion (3 replicas, nginx:1.21) |
| `green-deployment.yaml` | Ejercicio 1 | Version Green nueva con readinessProbe (3 replicas, nginx:1.22) |
| `service-production.yaml` | Ejercicio 1 | NodePort 30080, selector inicial version=blue |
| `service-green-test.yaml` | Ejercicio 1 | NodePort 30081, solo Pods Green para testing |
| `app-stable-v1.yaml` | Ejercicio 2 | Deployment estable 9 replicas (90% trafico) |
| `app-canary-v2.yaml` | Ejercicio 2 | Deployment canary 1 replica (10% trafico) con readinessProbe |
| `service-canary.yaml` | Ejercicio 2 | NodePort 30082, selecciona stable + canary |
| `weighted-canary.yaml` | Ejercicio 3 | Multi-documento: app-v1 (4r) + app-v2 (1r) + service ClusterIP |
| `canary-with-health.yaml` | Ejercicio 4 | Multi-documento: stable con liveness+readiness + service |
| `canary-failing.yaml` | Ejercicio 4 | Canary con busybox que falla health checks (demostracion) |

Cada archivo incluye:
- Comentario de uso en la primera linea (`# Uso: kubectl apply -f ...`)
- Descripcion del proposito y comportamiento esperado
- Namespace declarado en el manifiesto (`lab-estrategias`)
- Resource requests y limits en todos los containers

## Script Incluido

| Archivo | Descripcion |
|---------|-------------|
| `blue-green-deploy.sh` | Script interactivo para automatizar el proceso Blue-Green completo |
| `cleanup.sh` | Elimina todos los recursos del laboratorio |

## Preparacion del Namespace

```bash
# Crear namespace dedicado para el laboratorio
kubectl create namespace lab-estrategias

# Establecer como namespace activo (opcional)
kubectl config set-context --current --namespace=lab-estrategias

# Verificar
kubectl get ns lab-estrategias
```

**Output esperado**:
```
NAME              STATUS   AGE
lab-estrategias   Active   5s
```
