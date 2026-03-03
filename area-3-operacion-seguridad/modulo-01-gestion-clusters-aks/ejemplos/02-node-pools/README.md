# Ejemplo 02: Node Pools en AKS

**Nivel:** Intermedio | **Duración:** 20 min

## Descripción

Este ejemplo muestra cómo gestionar node pools en AKS: agregar user node pools con diferentes tamaños de VM, configurar labels y taints, y escalar pools.

## Prerrequisitos

- Cluster AKS existente (ver Ejemplo 01)
- Azure CLI autenticado

## Conceptos Clave

| Concepto | Descripción |
|----------|-------------|
| System Node Pool | Pool obligatorio para componentes del sistema |
| User Node Pool | Pool para aplicaciones de usuario |
| Node Labels | Etiquetas para identificar nodos por pool |
| Node Taints | Restricciones para controlar qué Pods se ejecutan |

## Pasos

### 1. Agregar User Node Pool para Aplicaciones

```bash
az aks nodepool add \
  --resource-group rg-ejemplo-aks \
  --cluster-name aks-ejemplo \
  --name apppool \
  --node-count 3 \
  --node-vm-size Standard_D4s_v3 \
  --labels workload=applications tier=production
```

### 2. Agregar Node Pool para GPU (Machine Learning)

```bash
az aks nodepool add \
  --resource-group rg-ejemplo-aks \
  --cluster-name aks-ejemplo \
  --name gpupool \
  --node-count 1 \
  --node-vm-size Standard_NC6s_v3 \
  --node-taints sku=gpu:NoSchedule \
  --labels workload=ml hardware=gpu
```

### 3. Listar Node Pools

```bash
az aks nodepool list \
  --resource-group rg-ejemplo-aks \
  --cluster-name aks-ejemplo \
  -o table
```

### 4. Desplegar App en Pool Específico

```bash
kubectl apply -f node-pool-selector.yaml
```

## Archivo YAML: node-pool-selector.yaml

```yaml
# Uso: kubectl apply -f node-pool-selector.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-en-pool-especifico
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mi-app
  template:
    metadata:
      labels:
        app: mi-app
    spec:
      nodeSelector:
        agentpool: apppool    # Solo se ejecuta en el pool "apppool"
      containers:
      - name: app
        image: nginx:1.25-alpine
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
```

## Limpieza

```bash
./cleanup.sh
```

## Navegación

- ⬆️ [Índice de ejemplos](../README.md)
