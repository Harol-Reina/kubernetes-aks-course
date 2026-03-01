# Capítulo 29: Gestión de Clústeres AKS

Con los fundamentos de Kubernetes dominados en un entorno local, damos el salto a la nube. Azure Kubernetes Service (AKS) es un servicio gestionado que simplifica la creación, configuración y gestión de clusters Kubernetes en producción. En este capítulo aprendemos a administrarlo tanto desde el portal como desde la línea de comandos.

---

## Administración a través de Azure Portal

### Acceso al Portal

1. **Navegación**: Azure Portal → Kubernetes services
2. **Overview**: Estado general del clúster
3. **Node pools**: Gestión de grupos de nodos
4. **Networking**: Configuración de red
5. **Security**: Configuraciones de seguridad
6. **Monitoring**: Métricas y logs

### Operaciones Básicas en Portal

**Scaling del Clúster:**
```
Portal → AKS → Node pools → Scale
- Manual scaling
- Auto-scaling configuration
- Node pool settings
```

**Upgrade del Clúster:**
```
Portal → AKS → Upgrade
- Kubernetes version
- Rolling upgrade
- Maintenance windows
```

## Administración con Azure CLI

### Comandos Fundamentales

```bash
# Listar clústeres AKS
az aks list --output table

# Obtener información detallada
az aks show \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course

# Estado del clúster
az aks get-credentials \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course

# Verificar versiones disponibles
az aks get-versions --location eastus --output table
```

### Scaling y Actualización

```bash
# Escalar node pool
az aks scale \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --node-count 3

# Habilitar autoscaling
az aks update \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 5

# Actualizar versión de Kubernetes
az aks upgrade \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --kubernetes-version 1.28.0
```

### Node Pools Adicionales

```bash
# Crear node pool adicional
az aks nodepool add \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name workerpool \
  --node-count 2 \
  --node-vm-size Standard_D2s_v3 \
  --node-taints dedicated=worker:NoSchedule

# Listar node pools
az aks nodepool list \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --output table

# Eliminar node pool
az aks nodepool delete \
  --resource-group rg-kubernetes-course \
  --cluster-name aks-k8s-course \
  --name workerpool
```

## Integración con Azure Container Registry

### Configuración de ACR

```bash
# Attach ACR al clúster AKS
az aks update \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --attach-acr acrk8scourse

# Verificar integración
az aks check-acr \
  --resource-group rg-kubernetes-course \
  --name aks-k8s-course \
  --acr acrk8scourse
```

### Usar Imágenes desde ACR

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-from-acr
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: acrk8scourse.azurecr.io/mi-app-nodejs:latest
        ports:
        - containerPort: 3000
```

---

## Resumen del Capítulo

En este capítulo cubrimos la gestión de clústeres AKS desde dos interfaces: Azure Portal para operaciones visuales y Azure CLI para automatización. Aprendimos a escalar node pools, actualizar versiones de Kubernetes, crear pools especializados con taints, e integrar Azure Container Registry para usar imágenes privadas. Estos son los cimientos para operar Kubernetes en producción sobre Azure.
