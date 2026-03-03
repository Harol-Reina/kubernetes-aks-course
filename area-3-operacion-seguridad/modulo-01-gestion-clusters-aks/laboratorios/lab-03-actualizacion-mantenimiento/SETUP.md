# Setup - Lab 03: Actualización y Mantenimiento

## Prerrequisitos

| Requisito | Verificación |
|-----------|-------------|
| Cluster AKS existente | `kubectl get nodes` |
| Azure CLI autenticado | `az account show` |
| Al menos 2 nodos | `kubectl get nodes` (para practicar drain) |

## Verificación

```bash
az aks show --resource-group rg-lab-aks --name aks-lab-01 -o table
kubectl get nodes -o wide
```
