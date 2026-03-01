# SETUP - Lab 01: Liveness y Readiness Probes

## Requisitos Previos

- Cluster Kubernetes funcional (Minikube recomendado)
- kubectl configurado y conectado al cluster
- Conocimientos basicos de Pods, Deployments y Services

## Requisitos Minikube

> Este laboratorio funciona con la configuracion por defecto de Minikube.

No se requieren addons adicionales.

## Verificacion del Entorno

```bash
kubectl cluster-info
kubectl get nodes
kubectl auth can-i create pods
kubectl auth can-i create services

# Verificar archivos YAML del laboratorio
ls *.yaml
```

**Salida esperada de `ls *.yaml`:**

```
broken-liveness.yaml
combined-probes.yaml
liveness-exec.yaml
liveness-http.yaml
readiness-deployment.yaml
```

## Archivos del Laboratorio

| Archivo | Descripcion |
|---------|-------------|
| `liveness-http.yaml` | Pod con Liveness Probe HTTP (agnhost) |
| `liveness-exec.yaml` | Pod con Liveness Probe Exec (busybox) |
| `readiness-deployment.yaml` | Deployment 3 replicas con Readiness + Liveness |
| `combined-probes.yaml` | Pod con Liveness + Readiness combinadas |
| `broken-liveness.yaml` | Pod con probe rota (troubleshooting) |
| `cleanup.sh` | Script de limpieza |
