# Ejemplo 01: Crear Cluster AKS

**Nivel:** Básico | **Duración:** 15 min

## Descripción

Este ejemplo muestra cómo crear un cluster AKS desde cero usando Azure CLI, incluyendo la creación del resource group, el cluster, y la conexión de kubectl.

## Prerrequisitos

- Azure CLI instalado y autenticado (`az login`)
- Suscripción Azure activa con cuota de CPU disponible

## Pasos

### 1. Crear Resource Group

```bash
az group create \
  --name rg-ejemplo-aks \
  --location eastus
```

### 2. Crear Cluster AKS

```bash
az aks create \
  --resource-group rg-ejemplo-aks \
  --name aks-ejemplo \
  --node-count 2 \
  --node-vm-size Standard_D2s_v3 \
  --enable-managed-identity \
  --generate-ssh-keys
```

### 3. Conectar kubectl

```bash
az aks get-credentials \
  --resource-group rg-ejemplo-aks \
  --name aks-ejemplo
```

### 4. Verificar

```bash
kubectl get nodes
kubectl cluster-info
```

## Salida Esperada

```
NAME                                STATUS   ROLES    AGE   VERSION
aks-nodepool1-12345678-vmss000000   Ready    <none>   2m    v1.28.0
aks-nodepool1-12345678-vmss000001   Ready    <none>   2m    v1.28.0
```

## Limpieza

```bash
./cleanup.sh
```

## Navegación

- ⬆️ [Índice de ejemplos](../README.md)
