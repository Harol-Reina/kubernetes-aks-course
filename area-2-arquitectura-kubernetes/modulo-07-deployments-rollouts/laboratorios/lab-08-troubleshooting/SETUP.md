# Prerequisitos - Lab 08: Proyecto Integrador - Deployment Completo

## Conocimientos Previos

- Laboratorios 1 al 7 del modulo completados (o conocimiento equivalente)
- Dominio de Deployments, ReplicaSets y estrategias de despliegue
- Familiaridad con RollingUpdate, Blue-Green y Rollback
- Comprension de HPA (HorizontalPodAutoscaler) y PDB (PodDisruptionBudget)
- Conocimiento de ConfigMaps, Secrets y probes (readiness, liveness, startup)

## Herramientas Necesarias

- Minikube o cluster Kubernetes funcional (version >= 1.24)
- kubectl configurado y conectado al cluster
- metrics-server habilitado (para HPA en Parte 4)
- Dos terminales disponibles (para monitoreo simultaneo con watch)

## Verificacion del Entorno

```bash
# Verificar cluster activo
kubectl cluster-info

# Verificar version de kubernetes
kubectl version --short

# Verificar que puedes crear namespaces
kubectl auth can-i create namespaces

# Habilitar metrics-server en minikube (requerido para HPA)
minikube addons enable metrics-server

# Verificar metrics-server activo
kubectl top nodes
```

**Output esperado de kubectl top nodes**:
```
NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
minikube   250m         12%    1024Mi          40%
```

```bash
# Verificar archivos YAML del laboratorio
ls -la /ruta/al/lab-08-troubleshooting/*.yaml
```

**Output esperado**:
```
frontend-configmap.yaml
frontend-deployment.yaml
frontend-service.yaml
frontend-hpa.yaml
frontend-deployment-green.yaml
backend-product-service.yaml
backend-order-service.yaml
pdb.yaml
```

## Archivos YAML Incluidos

Este laboratorio incluye 8 archivos YAML organizados por componente y funcion:

| Archivo | Tipo | Descripcion | Parte |
|---------|------|-------------|-------|
| `frontend-configmap.yaml` | ConfigMap | nginx.conf + app-config.json para el frontend | 2 |
| `frontend-deployment.yaml` | Deployment | Frontend production-ready (5 replicas, security hardened) | 2 |
| `frontend-service.yaml` | Service | ClusterIP con sessionAffinity para el frontend | 2 |
| `frontend-hpa.yaml` | HPA | Escalado automatico CPU 70% / Memory 80% (min:3, max:15) | 4 |
| `frontend-deployment-green.yaml` | Deployment | Version Green para Blue-Green strategy (nginx:1.22) | 6 |
| `backend-product-service.yaml` | Deployment + Service | product-service (3 replicas, zero-downtime) + Service:8080 | 3 |
| `backend-order-service.yaml` | Deployment + Service | order-service (4 replicas, rapido) + Service:8081 | 3 |
| `pdb.yaml` | PodDisruptionBudget x3 | PDBs para frontend, product-service y order-service | 5 |

Cada archivo incluye:
- Comentario de cabecera con numero de parte, uso, descripcion detallada y namespace
- Labels descriptivos (`app`, `tier`, `version`, `component`)
- Resource requests/limits en todos los Deployments
- Namespace `ecommerce-prod` declarado en cada manifiesto

## Nota sobre Secrets

Los Secrets se crean de forma imperativa con `kubectl create secret` durante el laboratorio.
No se incluye un archivo YAML para el Secret porque contiene credenciales y no debe
versionarse en el repositorio de forma plana.
