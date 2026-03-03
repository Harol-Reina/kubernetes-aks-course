# Lab 02: Node Pools y Scaling en AKS

**Duración:** 40 minutos | **Nivel:** Intermedio

## Objetivos

- Crear y gestionar diferentes tipos de node pools
- Configurar Cluster Autoscaler
- Configurar Horizontal Pod Autoscaler (HPA)
- Entender la interacción entre HPA y Cluster Autoscaler

## Técnicas y Conceptos Utilizados

| Técnica | Descripción |
|---------|-------------|
| `az aks nodepool add` | Crear node pools especializados |
| `az aks nodepool scale` | Escalar manualmente un pool |
| `kubectl autoscale` | Crear HPA para un Deployment |
| Node Selectors | Dirigir Pods a pools específicos |

---

## Paso 1: Crear Node Pools Especializados (10 min)

```bash
# Pool para aplicaciones web (compute optimizado)
az aks nodepool add \
  --resource-group rg-lab-aks \
  --cluster-name aks-lab-01 \
  --name webpool \
  --node-count 2 \
  --node-vm-size Standard_D4s_v3 \
  --labels workload=web

# Pool para jobs batch (puede escalar a cero)
az aks nodepool add \
  --resource-group rg-lab-aks \
  --cluster-name aks-lab-01 \
  --name batchpool \
  --node-count 0 \
  --node-vm-size Standard_D2s_v3 \
  --enable-cluster-autoscaler \
  --min-count 0 \
  --max-count 5 \
  --labels workload=batch
```

## Paso 2: Desplegar Apps en Pools Específicos (8 min)

```bash
# Desplegar webapp en el webpool
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      nodeSelector:
        agentpool: webpool
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"
EOF
```

## Paso 3: Configurar HPA (8 min)

```bash
# Crear HPA para la webapp
kubectl autoscale deployment webapp \
  --min=3 --max=10 --cpu-percent=50

# Observar el HPA
kubectl get hpa -w
```

## Paso 4: Generar Carga y Observar Escalado (10 min)

```bash
# Generar tráfico para activar el HPA
kubectl run load-test --image=busybox --rm -it -- \
  sh -c "while true; do wget -q -O- http://webapp; done"

# En otra terminal: observar Pods y nodos
kubectl get pods -w
kubectl get nodes -w
```

## Paso 5: Limpieza (4 min)

```bash
./cleanup.sh
```

## Troubleshooting

### HPA muestra "unknown" en TARGETS
**Causa:** metrics-server no está corriendo o no tiene datos aún.
**Solución:** Esperar 1-2 minutos para que metrics-server recolecte datos.

### Cluster Autoscaler no escala
**Causa:** Los Pods no están en Pending (hay recursos suficientes).
**Solución:** Aumentar las réplicas del HPA o los requests de los Pods.

## Navegación

- ⬅️ [Lab 01](../lab-01-crear-administrar-cluster/)
- ⬆️ [Índice](../README.md)
- ➡️ [Lab 03](../lab-03-actualizacion-mantenimiento/)
