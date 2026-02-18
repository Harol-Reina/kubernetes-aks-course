# Ejemplo 01: Calico Custom Configuration

## 🎯 Objetivo
Configuración personalizada de Calico CNI para clusters Kubernetes.

## 📝 Descripción
Archivo de configuración de Calico con:
- IP Pool personalizado
- Modo de red (IPIP, VXLAN)
- BGP configuration
- Network policies habilitadas

## 🚀 Uso

```bash
# Aplicar Calico con configuración custom
kubectl apply -f calico-custom.yaml

# Verificar pods de Calico
kubectl get pods -n kube-system -l k8s-app=calico-node

# Verificar IP Pool
kubectl get ippools
```

## 📊 Qué incluye

- ConfigMap de Calico
- DaemonSet de calico-node
- Deployment de calico-kube-controllers
- IP Pool configuration
- Network policy support

## 🧪 Verificación

```bash
# Ver configuración de Calico
kubectl get configmap -n kube-system calico-config -o yaml

# Test de conectividad entre pods
kubectl run test1 --image=busybox --command sleep 3600
kubectl run test2 --image=busybox --command sleep 3600
kubectl exec test1 -- ping -c 3 <test2-ip>
```

[Volver a ejemplos](../README.md)
