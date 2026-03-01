# Capítulo 36: Alta Disponibilidad y Autoescalado

Con monitoreo en su lugar, aseguramos que las aplicaciones se adapten a la demanda automáticamente. Kubernetes ofrece tres niveles de autoescalado: Pods (HPA/VPA), Nodes (Cluster Autoscaler) y protección contra disrupciones (PDB).

---

## Horizontal Pod Autoscaler (HPA)

El **HPA** escala automáticamente el número de Pods basándose en métricas como CPU, memoria o métricas personalizadas.

### Configuración Básica de HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
  namespace: desarrollo
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sample-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

## Vertical Pod Autoscaler (VPA)

El **VPA** ajusta automáticamente los requests y limits de CPU y memoria.

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: app-vpa
  namespace: desarrollo
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sample-app
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: app
      controlledResources: ["cpu", "memory"]
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 2
        memory: 2Gi
```

## Cluster Autoscaler

El **Cluster Autoscaler** ajusta automáticamente el número de nodos en el clúster.

```bash
# Habilitar Cluster Autoscaler en AKS
az aks update \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 5

# Configurar profile de autoscaling
az aks update \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --cluster-autoscaler-profile scale-down-delay-after-add=10m,scale-down-unneeded-time=10m
```

## Pod Disruption Budgets (PDB)

Los **PDB** definen el número mínimo de Pods que deben estar disponibles durante disrupciones voluntarias.

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
  namespace: desarrollo
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: sample-app
```

## Laboratorio 4.4: Configurar Autoescalado

### Paso 1: Aplicación con Resource Requests

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stress-app
  namespace: desarrollo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: stress-app
  template:
    metadata:
      labels:
        app: stress-app
    spec:
      containers:
      - name: stress
        image: nginx:1.21
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: stress-app-service
  namespace: desarrollo
spec:
  selector:
    app: stress-app
  ports:
  - port: 80
    targetPort: 80
EOF
```

### Paso 2: Configurar HPA

```bash
# Crear HPA
kubectl autoscale deployment stress-app \
  --namespace=desarrollo \
  --cpu-percent=50 \
  --min=2 \
  --max=10

# Verificar HPA
kubectl get hpa -n desarrollo
kubectl describe hpa stress-app -n desarrollo
```

### Paso 3: Generar Carga y Probar Autoscaling

```bash
# Pod generador de carga
kubectl run load-generator \
  --image=busybox \
  --restart=Never \
  --namespace=desarrollo \
  -- /bin/sh -c "while true; do wget -q -O- http://stress-app-service; done"

# Monitorear HPA
kubectl get hpa stress-app -n desarrollo --watch

# Ver escalado de pods
kubectl get pods -n desarrollo -l app=stress-app --watch

# Limpiar carga
kubectl delete pod load-generator -n desarrollo
```

### Paso 4: Configurar PDB

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: stress-app-pdb
  namespace: desarrollo
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: stress-app
EOF

# Verificar PDB
kubectl get pdb -n desarrollo
kubectl describe pdb stress-app-pdb -n desarrollo
```

---

## Resumen del Capítulo

La alta disponibilidad en Kubernetes se logra con tres mecanismos de autoescalado: HPA escala Pods horizontalmente basándose en métricas, VPA ajusta recursos verticalmente, y Cluster Autoscaler añade o elimina nodos. Los Pod Disruption Budgets protegen la disponibilidad durante mantenimiento. Juntos, estos mecanismos permiten que las aplicaciones se adapten a la demanda sin intervención manual.
