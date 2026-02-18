# Ejemplos - Módulo 22: Cluster Setup con Kubeadm

> **Enfoque**: Archivos de configuración para instalación y setup de clusters  
> **Total**: 4 configuraciones de producción

## 📁 Estructura

```
ejemplos/
├── README.md                   # Este archivo
├── 01-calico-custom/          # Calico CNI personalizado
│   ├── README.md
│   ├── calico-custom.yaml
│   └── cleanup.sh
├── 02-containerd-config/      # Configuración de containerd
│   ├── README.md
│   ├── containerd-config.toml
│   └── cleanup.sh
├── 03-kubeadm-config/         # Kubeadm init config
│   ├── README.md
│   ├── kubeadm-config.yaml
│   └── cleanup.sh
└── 04-kubeadm-ha-config/      # Kubeadm HA config
    ├── README.md
    ├── kubeadm-ha-config.yaml
    └── cleanup.sh
```

## 📋 Configuraciones Disponibles

### [01: Calico Custom](./01-calico-custom/)
Configuración personalizada de Calico CNI

**Características:**
- ✅ Control plane de un solo nodo
- ✅ Configuración de API server con audit logging
- ✅ Configuración de kubelet con systemd cgroup driver
- ✅ Configuración de kube-proxy con IPVS mode
- ✅ Parámetros de etcd optimizados
- ✅ Configuraciones de red (Pod CIDR, Service CIDR)

**Uso:**
```bash
# Inicializar control plane con configuración personalizada
sudo kubeadm init --config kubeadm-config.yaml

# Verificar configuración aplicada
kubectl cluster-info
kubectl get nodes -o wide
```

**Personalizar:**
- `localAPIEndpoint.advertiseAddress`: IP del control plane
- `controlPlaneEndpoint`: Hostname/IP del endpoint
- `networking.podSubnet`: CIDR de pods (debe coincidir con CNI)
- `apiServer.certSANs`: SANs adicionales para certificado API server

---

### 2. **kubeadm-ha-config.yaml**
Configuración para cluster High Availability con 3+ control plane nodes.

**Características:**
- ✅ 3 control plane nodes (recomendado: impar)
- ✅ Load balancer endpoint para HA
- ✅ Leader election para controller-manager y scheduler
- ✅ Etcd en topología stacked (co-located)
- ✅ Certificate SANs para todos los control planes
- ✅ Configuraciones de failover

**Arquitectura:**
```
                Load Balancer (HAProxy/nginx)
                     192.168.1.100:6443
                            |
         +------------------+------------------+
         |                  |                  |
   Control Plane 1    Control Plane 2    Control Plane 3
   192.168.1.10       192.168.1.11       192.168.1.12
   (API + etcd)       (API + etcd)       (API + etcd)
         |                  |                  |
         +------------------+------------------+
                            |
                    Worker Nodes Pool
```

**Uso:**
```bash
# En el PRIMER control plane
sudo kubeadm init --config kubeadm-ha-config.yaml --upload-certs

# Guardar el output:
# - certificate-key para control planes adicionales
# - token para workers

# En control planes ADICIONALES
sudo kubeadm join k8s-lb.example.com:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <certificate-key>

# En workers
sudo kubeadm join k8s-lb.example.com:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

**Load Balancer:**
Configurar HAProxy o nginx para balancear tráfico API server (puerto 6443).

Ejemplo HAProxy:
```
frontend kubernetes-frontend
    bind *:6443
    mode tcp
    default_backend kubernetes-backend

backend kubernetes-backend
    mode tcp
    balance roundrobin
    server master-01 192.168.1.10:6443 check
    server master-02 192.168.1.11:6443 check
    server master-03 192.168.1.12:6443 check
```

---

### 3. **containerd-config.toml**
Configuración optimizada del container runtime containerd.

**Características:**
- ✅ SystemdCgroup = true (CRÍTICO para Kubernetes)
- ✅ Sandbox image sincronizada con Kubernetes
- ✅ CNI plugin configuration
- ✅ Registry mirrors para private registries
- ✅ GRPC settings optimizados
- ✅ Garbage collection configurado

**Instalación:**
```bash
# Generar configuración por defecto
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# O usar configuración personalizada
sudo cp containerd-config.toml /etc/containerd/config.toml

# Reiniciar containerd
sudo systemctl restart containerd
sudo systemctl status containerd

# Verificar configuración
sudo crictl info
sudo crictl images
```

**Puntos críticos:**
- **SystemdCgroup = true**: Debe coincidir con kubelet cgroupDriver
- **sandbox_image**: Debe coincidir con versión de Kubernetes
- **Registry mirrors**: Configurar para private registries (Harbor, Nexus)

---

### 4. **calico-custom.yaml**
Configuración personalizada del CNI plugin Calico.

**Características:**
- ✅ IPIP mode: CrossSubnet (mejor performance)
- ✅ MTU optimizado para redes overlay
- ✅ Prometheus metrics habilitados
- ✅ IP autodetection configurado
- ✅ BlockSize personalizado (/26 = 64 IPs por nodo)
- ✅ GlobalNetworkPolicy ejemplo

**Instalación:**
```bash
# Aplicar configuración personalizada
kubectl apply -f calico-custom.yaml

# Verificar instalación
kubectl get pods -n kube-system | grep calico
kubectl get daemonset -n kube-system calico-node

# Ver IP pools configurados (requiere calicoctl)
calicoctl get ippool -o wide

# Ver estado de nodos Calico
calicoctl node status
```

**Troubleshooting:**
```bash
# Logs de Calico node
kubectl logs -n kube-system -l k8s-app=calico-node

# Ver configuración aplicada
kubectl get configmap -n kube-system calico-config -o yaml

# Verificar conectividad de red
kubectl run test-pod --image=busybox --restart=Never -- sleep 3600
kubectl exec test-pod -- ping <pod-ip>
```

**Alternativas CNI:**
- **Flannel**: Simple, VXLAN overlay (menor performance)
- **Weave**: Mesh networking, encriptación built-in
- **Cilium**: eBPF-based, alto performance, observabilidad avanzada

---

## 🚀 Flujo de Instalación Completa

### Opción A: Cluster Single Master

```bash
# 1. Instalar prerequisites (todos los nodos)
sudo ./scripts/install-prerequisites.sh

# 2. Inicializar control plane (solo master)
sudo kubeadm init --config ejemplos/kubeadm-config.yaml

# 3. Configurar kubeconfig
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 4. Instalar CNI (Calico)
kubectl apply -f ejemplos/calico-custom.yaml

# 5. Verificar control plane
kubectl get nodes
kubectl get pods -n kube-system

# 6. Obtener join command para workers
kubeadm token create --print-join-command

# 7. En workers: ejecutar join command
sudo kubeadm join <control-plane-ip>:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

### Opción B: Cluster High Availability

```bash
# 1. Configurar load balancer (HAProxy/nginx) en servidor separado
# Ver ejemplo de configuración en kubeadm-ha-config.yaml

# 2. Instalar prerequisites (todos los control planes y workers)
sudo ./scripts/install-prerequisites.sh

# 3. Inicializar PRIMER control plane
sudo kubeadm init --config ejemplos/kubeadm-ha-config.yaml --upload-certs

# 4. Guardar outputs:
#    - certificate-key (para control planes adicionales)
#    - join command para control planes
#    - join command para workers

# 5. Configurar kubeconfig en primer master
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 6. Instalar CNI (Calico)
kubectl apply -f ejemplos/calico-custom.yaml

# 7. Agregar control planes ADICIONALES (master-02, master-03)
sudo kubeadm join k8s-lb.example.com:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <certificate-key>

# 8. Agregar workers
sudo kubeadm join k8s-lb.example.com:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>

# 9. Verificar HA cluster
kubectl get nodes -o wide
kubectl get pods -n kube-system -o wide
kubectl get endpoints -n kube-system  # Ver etcd endpoints
```

---

## 🔧 Personalización

### Cambiar Pod Network CIDR

1. Modificar en `kubeadm-config.yaml`:
```yaml
networking:
  podSubnet: 10.244.0.0/16  # Cambiar según necesidad
```

2. Actualizar en `calico-custom.yaml`:
```yaml
data:
  calico_ipv4pool_cidr: "10.244.0.0/16"  # Debe coincidir
```

### Configurar Private Registry

1. Modificar en `containerd-config.toml`:
```toml
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."private-registry.example.com"]
  endpoint = ["https://private-registry.example.com"]
```

2. Agregar credentials (si requiere autenticación):
```bash
crictl pull private-registry.example.com/image:tag \
  --creds username:password
```

---

## 📚 Referencias

- [kubeadm Configuration (v1beta3)](https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/)
- [Calico Documentation](https://docs.projectcalico.org/)
- [containerd Configuration](https://github.com/containerd/containerd/blob/main/docs/ops.md)
- [Creating Highly Available Clusters](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/)

---

## ⚠️ Notas Importantes

1. **CIDR de Red**: Asegurar que `podSubnet` no colisione con redes existentes
2. **SystemdCgroup**: Debe estar en `true` en containerd para systemd
3. **Certificate SANs**: Incluir todas las IPs/hostnames del API server
4. **Token Expiration**: Tokens por defecto expiran en 24h, regenerar si es necesario
5. **etcd Backup**: Configurar backups automáticos antes de producción
6. **Load Balancer**: Para HA, el LB es un SPOF - considerar redundancia

---

**Ver también:**
- [Laboratorios](../laboratorios/README.md) - Labs prácticos paso a paso
- [Scripts](../scripts/) - Scripts de automatización
- [README principal](../README.md) - Documentación completa del módulo
