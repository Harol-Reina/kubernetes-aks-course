# Ejemplo 03: Kubeadm Init Configuration

## 🎯 Objetivo
Archivo de configuración para `kubeadm init` en cluster single-master.

## 📝 Descripción
Configuración kubeadm que especifica:
- Versión de Kubernetes
- Networking (pod CIDR, service CIDR)
- API server settings
- Scheduler y controller manager options

## 🚀 Uso

```bash
# Inicializar cluster con esta configuración
sudo kubeadm init --config kubeadm-config.yaml

# Configurar kubectl para usuario
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Aplicar CNI (Calico o Flannel)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

## 📊 Configuraciones clave

- `kubernetesVersion`: Versión específica de K8s
- `podSubnet`: CIDR para pods (ej: 192.168.0.0/16)
- `serviceSubnet`: CIDR para services
- `controlPlaneEndpoint`: IP/DNS del control plane

## 🧪 Verificación post-init

```bash
# Ver componentes del control plane
kubectl get pods -n kube-system

# Ver nodos
kubectl get nodes

# Ver configuración del cluster
kubectl cluster-info
```

[Volver a ejemplos](../README.md)
