# Ejemplo 04: Actualización de Cluster AKS

**Nivel:** Avanzado | **Duración:** 15 min

## Descripción

Proceso de actualización de la versión de Kubernetes en un cluster AKS, incluyendo preparación, verificación y rollback.

## Conceptos Clave

```
Proceso de Upgrade AKS:

1. Verificar versiones  →  2. Preparar PDBs  →  3. Upgrade control plane
                                                         │
4. Verificar cluster  ←  5. Upgrade node pools  ←───────┘
```

## Pasos

### 1. Ver versión actual

```bash
az aks show --resource-group rg-ejemplo-aks --name aks-ejemplo \
  --query "kubernetesVersion" -o tsv
```

### 2. Ver versiones disponibles

```bash
az aks get-upgrades \
  --resource-group rg-ejemplo-aks \
  --name aks-ejemplo \
  -o table
```

### 3. Verificar PDBs antes del upgrade

```bash
kubectl get pdb -A
```

### 4. Ejecutar upgrade

```bash
az aks upgrade \
  --resource-group rg-ejemplo-aks \
  --name aks-ejemplo \
  --kubernetes-version 1.29.0
```

### 5. Verificar después del upgrade

```bash
kubectl get nodes -o wide
az aks show --resource-group rg-ejemplo-aks --name aks-ejemplo \
  --query "kubernetesVersion"
```

## Navegación

- ⬆️ [Índice de ejemplos](../README.md)
