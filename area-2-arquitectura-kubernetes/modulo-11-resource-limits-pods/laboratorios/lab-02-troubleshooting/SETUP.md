# Prerequisitos - Lab 02: Troubleshooting de Resource Limits

## Conocimientos Previos

- Modulo 11 Lab 01 completado (conceptos basicos de resource limits)
- Familiaridad con `kubectl describe`, `kubectl logs`, `kubectl get events`
- Conceptos basicos de CPU y memoria en Kubernetes (requests vs limits)

## Herramientas Necesarias

- Minikube, kind, k3s o cluster Kubernetes funcional (version 1.28+)
- kubectl configurado y conectado al cluster
- metrics-server habilitado en el cluster

## Verificacion del Entorno

```bash
# Verificar cluster activo
kubectl cluster-info

# Verificar nodos disponibles
kubectl get nodes

# Verificar metrics-server (requerido para kubectl top)
kubectl top nodes

# Si metrics-server no esta disponible en minikube:
# minikube addons enable metrics-server

# Verificar permisos minimos
kubectl auth can-i create pods
kubectl auth can-i create deployments

# Verificar archivos YAML del laboratorio
ls -la *.yaml *.sh
```

## Nota sobre metrics-server

El Ejercicio 5 y partes del Ejercicio 6 requieren `kubectl top pods` que depende
de metrics-server. Si no esta disponible, estos pasos mostraran:

```
error: Metrics API not available
```

Para habilitarlo en minikube:

```bash
minikube addons enable metrics-server
```

En kind o k3s, instalar con:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Archivos YAML Incluidos

Este laboratorio incluye 8 archivos YAML documentados y 1 script de limpieza.
Cada archivo YAML incluye:

- Comentario de uso (`# Uso: kubectl apply -f ...`)
- Descripcion de lo que hace el manifiesto
- Explicacion de los conceptos clave

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `oomkilled-demo.yaml` | 1 | Pod que provoca OOMKilled (Exit Code 137) |
| `cpu-throttling-demo.yaml` | 2 | Pod con CPU throttling por limite bajo |
| `cpu-no-throttling.yaml` | 2 | Pod sin limite de CPU para comparacion |
| `storage-eviction-demo.yaml` | 3 | Pod evicted por exceder ephemeral storage |
| `pending-demo.yaml` | 4 | Deployment con requests excesivos (Pods en Pending) |
| `metrics-demo.yaml` | 5 | Deployment para practicar kubectl top |
| `problem-app.yaml` | 6 | Aplicacion problematica con OOM + throttling |
| `problem-app-fixed.yaml` | 6 | Version corregida de la aplicacion |
| `cleanup.sh` | - | Script de limpieza de todos los recursos |
