# Setup - Lab 02: Node Pools y Scaling

## Prerrequisitos

| Requisito | Verificación |
|-----------|-------------|
| Cluster AKS existente | `kubectl get nodes` |
| Azure CLI autenticado | `az account show` |
| metrics-server habilitado | `kubectl top nodes` |

## Verificación

```bash
az aks show --resource-group rg-lab-aks --name aks-lab-01 --query "kubernetesVersion" -o tsv
kubectl get nodes -o wide
```
