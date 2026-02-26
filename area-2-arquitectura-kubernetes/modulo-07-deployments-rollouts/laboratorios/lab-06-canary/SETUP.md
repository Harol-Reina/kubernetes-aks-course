# Prerequisitos - Lab 06: Best Practices en Production

## Conocimientos Previos

- Laboratorio 1 (Crear Deployments) completado
- Laboratorio 2 (Rolling Updates) completado
- Laboratorio 3 (Rollback) completado
- Conocimiento de Deployments, Services y ConfigMaps
- Familiaridad con `kubectl apply` y manifiestos YAML

## Herramientas Necesarias

- Minikube o cluster Kubernetes funcional (v1.24+)
- kubectl configurado y conectado al cluster
- metrics-server habilitado (para el ejercicio de HPA)
- Dos terminales disponibles (para monitoreo simultáneo)

## Verificacion del Entorno

```bash
# Verificar cluster activo
kubectl cluster-info

# Verificar acceso al cluster
kubectl get nodes

# Verificar que puedes crear namespaces
kubectl auth can-i create namespaces

# Habilitar metrics-server en minikube (necesario para HPA)
minikube addons enable metrics-server

# Verificar metrics-server disponible (puede tardar ~60 segundos)
kubectl get apiservice v1beta1.metrics.k8s.io

# Verificar archivos YAML del laboratorio
ls -la /media/Data/Source/Courses/K8S/area-2-arquitectura-kubernetes/modulo-07-deployments-rollouts/laboratorios/lab-06-canary/*.yaml
```

**Output esperado de ls**:
```
production-deployment.yaml
webapp-configmap.yaml
webapp-hpa.yaml
webapp-ingress.yaml
webapp-networkpolicy.yaml
webapp-pdb.yaml
webapp-servicemonitor.yaml
webapp-service.yaml
webapp-with-config.yaml
```

## Archivos YAML Incluidos

Este laboratorio incluye 9 archivos YAML, uno por recurso o grupo de recursos relacionados:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `production-deployment.yaml` | Ejercicio 1 | Deployment con 5 replicas y todas las best practices |
| `webapp-configmap.yaml` | Ejercicio 2 | ConfigMap con configuracion nginx y variables |
| `webapp-with-config.yaml` | Ejercicio 2 | Deployment que consume ConfigMap y Secrets |
| `webapp-service.yaml` | Ejercicio 3 | Service ClusterIP con sticky sessions |
| `webapp-ingress.yaml` | Ejercicio 3 | Ingress con TLS y rate limiting |
| `webapp-hpa.yaml` | Ejercicio 4 | HorizontalPodAutoscaler v2 con CPU y memoria |
| `webapp-pdb.yaml` | Ejercicio 5 | Dos PodDisruptionBudgets (minAvailable y maxUnavailable) |
| `webapp-servicemonitor.yaml` | Ejercicio 6 | ServiceMonitor para Prometheus Operator |
| `webapp-networkpolicy.yaml` | Ejercicio 7 | NetworkPolicy restrictiva con ingress y egress |

Cada archivo incluye:
- Cabecera de comentarios con numero de ejercicio, comando de uso y descripcion
- Namespace declarado en el manifiesto (`lab-production`)
- Labels consistentes: `app`, `tier`, `environment`
- Comentarios inline explicando cada seccion relevante

## Preparacion Inicial

```bash
# Crear namespace del laboratorio
kubectl create namespace lab-production

# Establecer namespace activo para el laboratorio
kubectl config set-context --current --namespace=lab-production

# Verificar namespace creado
kubectl get ns lab-production
```

**Output esperado**:
```
NAME             STATUS   AGE
lab-production   Active   5s
```
