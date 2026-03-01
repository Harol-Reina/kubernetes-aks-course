# SETUP - Lab 02: Startup Probes y Casos Avanzados

## Requisitos Previos

- Cluster Kubernetes funcional (Minikube recomendado)
- kubectl configurado y conectado al cluster
- Lab 01 completado (conceptos de Liveness y Readiness)

## Requisitos Minikube

> Este laboratorio funciona con la configuracion por defecto de Minikube.

**Nota:** El Ejercicio 3 (Node.js) requiere acceso a internet para descargar
dependencias con `npm install`. Si el cluster no tiene acceso a internet,
puedes saltar ese ejercicio.

## Verificacion del Entorno

```bash
kubectl cluster-info
kubectl get nodes
kubectl auth can-i create pods
kubectl auth can-i create deployments

# Verificar archivos YAML del laboratorio
ls *.yaml
```

**Salida esperada de `ls *.yaml`:**

```
critical-app.yaml
nodejs-production.yaml
postgres-production.yaml
slow-app-without-startup.yaml
slow-app-with-startup.yaml
```

## Archivos del Laboratorio

| Archivo | Descripcion |
|---------|-------------|
| `slow-app-without-startup.yaml` | Pod de arranque lento sin Startup Probe (problema) |
| `slow-app-with-startup.yaml` | Pod de arranque lento con Startup Probe (solucion) |
| `postgres-production.yaml` | Pod PostgreSQL con las 3 probes |
| `nodejs-production.yaml` | Deployment Node.js con endpoints dedicados |
| `critical-app.yaml` | Deployment HA con probes optimizadas |
| `cleanup.sh` | Script de limpieza |
