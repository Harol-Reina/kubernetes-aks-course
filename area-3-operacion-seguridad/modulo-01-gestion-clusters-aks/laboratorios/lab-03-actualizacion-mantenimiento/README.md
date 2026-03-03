# Lab 03: Actualización y Mantenimiento de Cluster AKS

**Duración:** 35 minutos | **Nivel:** Intermedio

## Objetivos

- Actualizar la versión de Kubernetes en AKS
- Usar drain y cordon para mantenimiento de nodos
- Configurar PodDisruptionBudgets para disponibilidad
- Practicar procedimientos de mantenimiento seguro

## Técnicas y Conceptos Utilizados

| Técnica | Descripción |
|---------|-------------|
| `az aks upgrade` | Actualizar versión de K8s |
| `kubectl drain` | Evacuar Pods de un nodo |
| `kubectl cordon/uncordon` | Marcar nodo como no programable |
| PodDisruptionBudget | Garantizar disponibilidad mínima |

---

## Paso 1: Preparar Aplicación con PDB (8 min)

```bash
# Desplegar aplicación con 3 réplicas
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-critica
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app-critica
  template:
    metadata:
      labels:
        app: app-critica
    spec:
      containers:
      - name: app
        image: nginx:1.25-alpine
        resources:
          requests:
            cpu: "100m"
            memory: "64Mi"
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-critica-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: app-critica
EOF

# Verificar PDB
kubectl get pdb app-critica-pdb
```

## Paso 2: Simular Mantenimiento de Nodo (10 min)

```bash
# Marcar nodo como no programable (no acepta nuevos Pods)
kubectl cordon <nombre-nodo>

# Verificar que el nodo está marcado
kubectl get nodes
# Verás: SchedulingDisabled

# Evacuar Pods del nodo (respetando PDBs)
kubectl drain <nombre-nodo> --ignore-daemonsets --delete-emptydir-data

# Restaurar nodo
kubectl uncordon <nombre-nodo>
```

## Paso 3: Verificar Versiones de Upgrade (5 min)

```bash
# Ver versión actual
az aks show --resource-group rg-lab-aks --name aks-lab-01 \
  --query "kubernetesVersion" -o tsv

# Ver versiones disponibles para upgrade
az aks get-upgrades \
  --resource-group rg-lab-aks \
  --name aks-lab-01 \
  -o table
```

## Paso 4: Ejecutar Upgrade (si hay versión disponible) (8 min)

```bash
# NOTA: Solo ejecutar si hay una versión superior disponible
az aks upgrade \
  --resource-group rg-lab-aks \
  --name aks-lab-01 \
  --kubernetes-version <nueva-version>

# Verificar después del upgrade
kubectl get nodes -o wide
```

## Paso 5: Limpieza (4 min)

```bash
./cleanup.sh
```

## Navegación

- ⬅️ [Lab 02](../lab-02-node-pools-scaling/)
- ⬆️ [Índice](../README.md)
