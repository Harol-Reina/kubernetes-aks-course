# Prerequisitos - Lab 03: Services Avanzados

## Conocimientos Previos

- Laboratorios 01 y 02 completados
- Conceptos de StatefulSets (modulo anterior)
- Familiaridad con DNS de Kubernetes
- Familiaridad con `kubectl apply` y manifiestos YAML

## Herramientas Necesarias

- Minikube, kind, k3s o cluster Kubernetes funcional
- kubectl configurado y conectado al cluster
- Cluster con soporte para PersistentVolumes (para StatefulSet)
- Metrics server (para HPA, opcional)

## Verificacion del Entorno

```bash
# Verificar cluster activo
kubectl cluster-info

# Verificar StorageClass (para PVCs de StatefulSet)
kubectl get storageclass

# Verificar metrics server (opcional, para HPA)
kubectl top pods 2>/dev/null && echo "Metrics server OK" || echo "Metrics server no disponible"

# Verificar archivos YAML del laboratorio
ls -la *.yaml
```

## Archivos YAML Incluidos

Este laboratorio incluye 13 archivos YAML documentados.
Cada archivo incluye:

- Comentario de uso (`# Uso: kubectl apply -f ...`)
- Descripcion de lo que hace el manifiesto
- Explicacion de los conceptos clave

| Archivo | Descripcion |
|---------|-------------|
| `external-api-service.yaml` | ExternalName Service (api.github.com) |
| `database-service-phase1.yaml` | ExternalName para migracion (Fase 1) |
| `database-service-phase2.yaml` | ClusterIP para migracion (Fase 2) |
| `app-using-db.yaml` | App que consume Service "database" |
| `mysql-headless-service.yaml` | Headless Service (clusterIP: None) |
| `mysql-statefulset.yaml` | StatefulSet MySQL 3 replicas |
| `external-database-service.yaml` | Service sin selector |
| `external-database-endpoints.yaml` | Endpoints manuales |
| `app-using-external-db.yaml` | App que usa endpoints manuales |
| `production-service.yaml` | Service production-ready |
| `production-deployment.yaml` | Deployment production-ready |
| `webapp-pdb.yaml` | PodDisruptionBudget |
| `webapp-hpa.yaml` | HorizontalPodAutoscaler |
| `cleanup.sh` | Script de limpieza |
