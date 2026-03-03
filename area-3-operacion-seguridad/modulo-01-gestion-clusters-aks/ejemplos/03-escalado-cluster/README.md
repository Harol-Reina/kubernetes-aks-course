# Ejemplo 03: Escalado de Cluster AKS

**Nivel:** Intermedio | **Duración:** 20 min

## Descripción

Configuración de autoescalado en AKS: Cluster Autoscaler (escala nodos) y Horizontal Pod Autoscaler (escala Pods).

## Conceptos Clave

```
                    Más tráfico
                        │
                        ▼
┌─────────────────────────────────────────┐
│  HPA detecta alta CPU/memoria           │
│  → Crea más réplicas del Pod            │
└──────────────────┬──────────────────────┘
                   │ Si no hay nodos con
                   │ recursos disponibles...
                   ▼
┌─────────────────────────────────────────┐
│  Cluster Autoscaler detecta Pods        │
│  Pending → Agrega nodos al pool         │
└─────────────────────────────────────────┘
```

## Pasos

### 1. Habilitar Cluster Autoscaler

```bash
az aks nodepool update \
  --resource-group rg-ejemplo-aks \
  --cluster-name aks-ejemplo \
  --name nodepool1 \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 5
```

### 2. Crear Deployment con HPA

```bash
kubectl apply -f hpa-ejemplo.yaml
```

### 3. Generar carga para activar el escalado

```bash
kubectl run load-generator --image=busybox --rm -it -- \
  sh -c "while true; do wget -q -O- http://webapp-escalable; done"
```

### 4. Observar el escalado

```bash
kubectl get hpa -w
kubectl get pods -w
```

## Archivo: hpa-ejemplo.yaml

```yaml
# Uso: kubectl apply -f hpa-ejemplo.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-escalable
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp-escalable
  template:
    metadata:
      labels:
        app: webapp-escalable
    spec:
      containers:
      - name: app
        image: nginx:1.25-alpine
        resources:
          requests:
            cpu: "100m"
          limits:
            cpu: "200m"
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp-escalable
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

## Limpieza

```bash
./cleanup.sh
```

## Navegación

- ⬆️ [Índice de ejemplos](../README.md)
