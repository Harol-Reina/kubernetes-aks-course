# Prerequisitos - Lab 01: Fundamentos de Resource Limits

## Conocimientos Previos

- Modulos de Pods y Deployments completados (modulos 03-05)
- Familiaridad con `kubectl apply` y manifiestos YAML
- Conceptos basicos de CPU y memoria en sistemas operativos
- Modulo 11: haber leido la seccion de Requests vs Limits del README principal

## Herramientas Necesarias

- Minikube, kind, k3s o cluster Kubernetes funcional
- kubectl configurado y conectado al cluster
- metrics-server habilitado en el cluster (requerido para `kubectl top`)
- Terminal con acceso al cluster

## Verificacion del Entorno

```bash
# Verificar cluster activo
kubectl cluster-info

# Verificar nodos disponibles
kubectl get nodes

# Verificar permisos para crear Pods y Deployments
kubectl auth can-i create pods
kubectl auth can-i create deployments

# Verificar metrics-server disponible (requerido para kubectl top)
kubectl top nodes

# Verificar archivos YAML del laboratorio
ls *.yaml
```

### Habilitar metrics-server en Minikube (si no esta activo)

```bash
# Verificar addons disponibles
minikube addons list | grep metrics

# Habilitar metrics-server
minikube addons enable metrics-server

# Esperar hasta que metrics-server este listo (puede tardar 1-2 minutos)
kubectl rollout status deployment metrics-server -n kube-system

# Verificar que kubectl top funciona
kubectl top nodes
```

**Salida esperada de `kubectl top nodes`:**
```
NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
minikube   150m         3%     1200Mi          15%
```

Si `kubectl top nodes` devuelve error, espera 2 minutos mas para que metrics-server
recolecte datos iniciales antes de continuar con el laboratorio.

## Archivos YAML Incluidos

Este laboratorio incluye 5 archivos YAML documentados y un script de limpieza.
Cada archivo YAML incluye:

- Comentario de uso (`# Uso: kubectl apply -f ...`)
- Descripcion de lo que hace el manifiesto
- Explicacion de los conceptos clave

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `pod-basic.yaml` | 1 | Pod nginx con requests y limits basicos (QoS Burstable) |
| `qos-comparison.yaml` | 2 | Tres Pods comparando las 3 QoS Classes |
| `fill-node.yaml` | 3 | Deployment de 10 replicas para demostrar placement por requests |
| `multi-container.yaml` | 4 | Pod con contenedor principal y dos sidecars |
| `init-container.yaml` | 5 | Pod con init container que ilustra la regla del maximo |
| `cleanup.sh` | - | Script de limpieza de todos los recursos del laboratorio |
