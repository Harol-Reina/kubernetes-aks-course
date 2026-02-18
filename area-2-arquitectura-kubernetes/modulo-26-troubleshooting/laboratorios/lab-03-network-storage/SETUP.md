# Lab 03: Network & Storage - Setup

Laboratorio de troubleshooting avanzado de networking y storage.

## Prerrequisitos

- CNI plugin instalado (Calico, Flannel, etc.)
- Ingress Controller (nginx, traefik)
- StorageClass configurado o capacidad para crear PVs
- metrics-server (opcional, para algunos escenarios)

## Archivos

- `README.md` - Instrucciones completas
- `network-test-pods.yaml` - Pods de prueba
- `storage-examples.yaml` - PVs y PVCs de ejemplo
- `cleanup.sh` - Limpieza

## Verificación de Prerrequisitos

```bash
# CNI
kubectl get pods -n kube-system | grep -E "calico|flannel|weave|cilium"

# Ingress Controller
kubectl get pods -n ingress-nginx

# StorageClass
kubectl get sc

# metrics-server (opcional)
kubectl get pods -n kube-system | grep metrics-server
```
