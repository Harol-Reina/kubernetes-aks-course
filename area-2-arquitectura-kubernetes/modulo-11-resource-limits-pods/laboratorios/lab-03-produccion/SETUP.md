# Prerequisitos - Lab 03: Resource Limits en Produccion

## Conocimientos Previos

- Lab 01 (Fundamentos de Resource Limits) completado — recomendado
- Lab 02 (Troubleshooting de Resource Limits) completado — recomendado
- Familiaridad con StatefulSets, Deployments y CronJobs
- Conceptos basicos de QoS classes (Guaranteed, Burstable, BestEffort)

## Herramientas Necesarias

- Minikube, kind, k3s o cluster Kubernetes 1.28+ funcional
- kubectl configurado y conectado al cluster
- Helm (opcional, requerido para Ejercicio 5 con Prometheus)
- Git (opcional, requerido para instalar VPA desde codigo fuente)

## Requisitos por Ejercicio

| Ejercicio | Requisito | Obligatorio |
|-----------|-----------|-------------|
| Ejercicio 1: Tier System | metrics-server | Si |
| Ejercicio 2: VPA | VPA instalado en el cluster | No (opcional) |
| Ejercicio 3: HPA | metrics-server | Si |
| Ejercicio 4: Pod-level Resources | Kubernetes 1.34+ con feature gate PodLevelResources | No (opcional) |
| Ejercicio 5: Prometheus | Helm + Prometheus Operator | No (opcional) |
| Ejercicio 6: Best Practices | metrics-server + PriorityClass | Si |

## Verificacion del Entorno

```bash
# Verificar version de Kubernetes
kubectl version --short

# Verificar cluster activo y nodos
kubectl cluster-info
kubectl get nodes

# Verificar metrics-server (requerido para HPA y kubectl top)
kubectl top nodes
kubectl top pods -A

# Si metrics-server no esta activo en minikube:
minikube addons enable metrics-server

# Verificar permisos para crear namespaces
kubectl auth can-i create namespaces

# Verificar archivos YAML del laboratorio
ls -la *.yaml *.sh
```

## Instalacion de VPA (Ejercicio 2 - Opcional)

```bash
# Clonar repositorio de autoscaler
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler

# Instalar VPA
./hack/vpa-up.sh

# Verificar componentes de VPA
kubectl get pods -n kube-system | grep vpa
# Salida esperada:
# vpa-admission-controller-...   1/1     Running
# vpa-recommender-...            1/1     Running
# vpa-updater-...                1/1     Running
```

## Instalacion de Prometheus (Ejercicio 5 - Opcional)

```bash
# Agregar repositorio de Prometheus Community
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar Prometheus Operator (kube-prometheus-stack)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Verificar instalacion
kubectl get pods -n monitoring
```

## Nota sobre Pod-level Resources (Ejercicio 4)

El Ejercicio 4 usa la feature `PodLevelResources` disponible a partir de Kubernetes 1.34.
Si tu cluster es anterior a 1.34, puedes leer el manifiesto `pod-level-app.yaml` para
entender el concepto, pero el apply fallara. En ese caso, usa solo `container-level-app.yaml`
para el ejercicio de comparacion.

```bash
# Verificar si PodLevelResources esta habilitado (minikube)
minikube ssh -- cat /var/lib/kubelet/config.yaml | grep -A 10 featureGates
# Buscar: PodLevelResources: true
```

## Archivos YAML Incluidos

Este laboratorio incluye 12 archivos YAML documentados y 1 script de limpieza.
Cada archivo YAML incluye: comentario de uso, descripcion de 2-3 lineas y conceptos clave.

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `tier1-database.yaml` | 1 | StatefulSet PostgreSQL + Headless Service con QoS Guaranteed |
| `tier2-api.yaml` | 1 | Deployment API REST + Service con QoS Burstable y sidecar |
| `tier3-batch.yaml` | 1 | CronJob de reportes nocturnos con recursos bajos |
| `vpa-recommend.yaml` | 2 | VPA en modo Off (solo recomendaciones) para api-server |
| `vpa-auto.yaml` | 2 | VPA en modo Auto (actualizacion automatica) para postgres |
| `hpa-cpu.yaml` | 3 | HPA basado en CPU con politicas de scale up agresivo |
| `hpa-multi.yaml` | 3 | HPA con CPU y memoria simultaneamente |
| `hpa-custom.yaml` | 3 | HPA con metricas custom de Prometheus (RPS y latencia) |
| `pod-level-app.yaml` | 4 | Deployment con Pod-level resources K8s 1.34+ |
| `container-level-app.yaml` | 4 | Deployment con container-level resources (tradicional) |
| `prometheus-alerts.yaml` | 5 | ConfigMap con reglas de alerting para OOMKilled y throttling |
| `production-app.yaml` | 6 | Deployment completo con todas las best practices de produccion |
| `cleanup.sh` | - | Script de limpieza de todos los recursos del laboratorio |
