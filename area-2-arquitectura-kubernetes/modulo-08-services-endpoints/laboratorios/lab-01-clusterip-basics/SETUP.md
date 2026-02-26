# Prerequisitos - Lab 01: ClusterIP Basics

## Conocimientos Previos

- Modulos de Pods y Deployments completados
- Familiaridad con `kubectl apply` y manifiestos YAML
- Conceptos basicos de redes (IP, DNS, puertos)

## Herramientas Necesarias

- Minikube, kind, k3s o cluster Kubernetes funcional
- kubectl configurado y conectado al cluster
- Terminal con acceso al cluster

## Verificacion del Entorno

```bash
# Verificar cluster activo
kubectl cluster-info

# Verificar nodos disponibles
kubectl get nodes

# Verificar permisos
kubectl auth can-i create services

# Verificar archivos YAML del laboratorio
ls -la *.yaml
```

## Archivos YAML Incluidos

Este laboratorio incluye 3 archivos YAML documentados.
Cada archivo incluye:

- Comentario de uso (`# Uso: kubectl apply -f ...`)
- Descripcion de lo que hace el manifiesto
- Explicacion de los conceptos clave

| Archivo | Descripcion |
|---------|-------------|
| `backend-deployment.yaml` | Deployment con 3 replicas nginx:alpine |
| `backend-service.yaml` | Service ClusterIP para el backend |
| `pod-not-ready.yaml` | Pod con readinessProbe fallida (troubleshooting) |
| `test-loadbalancing.sh` | Script de verificacion de balanceo |
| `cleanup.sh` | Script de limpieza |
