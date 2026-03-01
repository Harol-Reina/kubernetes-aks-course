# SETUP - Lab 03: Troubleshooting de Health Checks

## Requisitos Previos

- Cluster Kubernetes funcional (Minikube recomendado)
- kubectl configurado y conectado al cluster
- Lab 01 y Lab 02 completados (conceptos de liveness, readiness, startup)

## Requisitos Minikube

> Este laboratorio funciona con la configuracion por defecto de Minikube.

El Problema 4 (Liveness bajo Carga) es una discusion ilustrativa. El comando
`kubectl top pods` requiere metrics-server:

```bash
minikube addons enable metrics-server
```

## Verificacion del Entorno

```bash
kubectl cluster-info
kubectl get nodes
kubectl auth can-i create pods
kubectl auth can-i create deployments
kubectl auth can-i create services

# Verificar archivos YAML del laboratorio
ls *.yaml
```

**Salida esperada de `ls *.yaml`:**

```
buggy-app.yaml
crashloop-pod.yaml
webapp-no-traffic.yaml
```

## Archivos del Laboratorio

| Archivo | Descripcion |
|---------|-------------|
| `crashloop-pod.yaml` | Pod con livenessProbe rota (CrashLoopBackOff) |
| `webapp-no-traffic.yaml` | Deployment + Service con selector incorrecto |
| `buggy-app.yaml` | Deployment con multiples errores de probes |
| `cleanup.sh` | Script de limpieza |
