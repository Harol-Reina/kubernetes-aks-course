# Ejemplo 01: Kubeadm Upgrade Configuration

## 🎯 Objetivo
Configuración para upgrade seguro de cluster Kubernetes usando kubeadm.

## 📝 Descripción
Config file para `kubeadm upgrade` especificando:
- Versión target de Kubernetes
- Configuraciones del API server
- Patches y customizaciones
- Networking configuration

## 🚀 Uso

```bash
# 1. Verificar versión actual
kubectl version --short
kubeadm version

# 2. Planear upgrade
sudo kubeadm upgrade plan

# 3. Aplicar upgrade con config
sudo kubeadm upgrade apply v1.28.0 --config kubeadm-upgrade-config.yaml

# 4. Verificar upgrade
kubectl get nodes
kubectl version
```

## 📊 Proceso completo de upgrade

```bash
# En CONTROL PLANE node:
# 1. Drenar nodo
kubectl drain <control-plane-node> --ignore-daemonsets

# 2. Actualizar kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update && sudo apt-get install -y kubeadm=1.28.0-00
sudo apt-mark hold kubeadm

# 3. Upgrade cluster
sudo kubeadm upgrade apply v1.28.0 --config kubeadm-upgrade-config.yaml

# 4. Actualizar kubelet y kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.28.0-00 kubectl=1.28.0-00
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# 5. Uncordon nodo
kubectl uncordon <control-plane-node>
```

## ⚠️ Best Practices

- Backup etcd antes de upgrade
- Test en ambiente no-prod primero
- Un nodo a la vez
- Esperar que cada nodo esté Ready
- Verificar addons funcionando

[Volver a ejemplos](../README.md)
