# SETUP - Prerequisitos del Laboratorio Integral AKS

## Que necesitas antes de empezar

### 1. Cluster AKS funcionando

Tu cluster ya debe existir. Verifica la conexion:

```bash
# Conectar kubectl al cluster (si no lo has hecho)
az aks get-credentials --resource-group <TU-RESOURCE-GROUP> --name <TU-CLUSTER-AKS>

# Verificar conexion
kubectl cluster-info

# Verificar nodos (deberias ver al menos 1)
kubectl get nodes -o wide
```

**Salida esperada**:
```
NAME                                STATUS   ROLES    AGE   VERSION   INTERNAL-IP   OS-IMAGE
aks-nodepool1-12345678-vmss000000   Ready    <none>   1d    v1.28.x   10.224.0.4    Ubuntu 22.04
```

### 2. Especificaciones del cluster

| Parametro | Valor requerido |
|-----------|----------------|
| VM Size | Standard_D4alds_v6 (4 vCPU, 8 GB RAM) |
| Nodos actuales | 1 (minimo) |
| Nodos maximo | 4 (autoscaler habilitado) |
| Disco por nodo | 30 GB |
| Cluster Autoscaler | Habilitado |

### 3. Herramientas en tu maquina local

```bash
# Azure CLI
az version
# Esperado: azure-cli 2.x.x o superior

# kubectl
kubectl version --client
# Esperado: v1.27+ o superior

# Helm 3
helm version
# Esperado: v3.x.x

# Si falta Helm, instalarlo:
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 4. Verificar que el cluster autoscaler esta habilitado

```bash
# Ver la configuracion del nodepool
az aks nodepool show \
    --resource-group <TU-RESOURCE-GROUP> \
    --cluster-name <TU-CLUSTER-AKS> \
    --name nodepool1 \
    --query '{autoscaling: enableAutoScaling, minCount: minCount, maxCount: maxCount, count: count}'
```

**Salida esperada**:
```json
{
  "autoscaling": true,
  "minCount": 1,
  "maxCount": 4,
  "count": 1
}
```

Si el autoscaler no esta habilitado:
```bash
az aks nodepool update \
    --resource-group <TU-RESOURCE-GROUP> \
    --cluster-name <TU-CLUSTER-AKS> \
    --name nodepool1 \
    --enable-cluster-autoscaler \
    --min-count 1 \
    --max-count 4
```

### 5. Verificar metrics-server

```bash
kubectl top nodes
```

Si da error "Metrics API not available", metrics-server no esta instalado. En AKS normalmente viene por defecto, pero si falta:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# Espera 1 minuto y vuelve a probar
kubectl top nodes
```

### 6. Espacio en disco del lab

El laboratorio crea recursos ligeros. No necesitas espacio extra en disco mas alla de este repositorio.

---

## Verificacion rapida (todo en un comando)

```bash
echo "=== Cluster ===" && kubectl cluster-info | head -2 && \
echo "=== Nodos ===" && kubectl get nodes && \
echo "=== Helm ===" && helm version --short && \
echo "=== Metrics ===" && kubectl top nodes 2>/dev/null || echo "(metrics-server no disponible aun)" && \
echo "=== LISTO para el laboratorio ==="
```
