# 📋 Módulo 22: Cluster Setup con kubeadm - Resumen Ejecutivo

## 🎯 Conceptos Clave

- **kubeadm**: Herramienta oficial para bootstrapping de clusters Kubernetes
- **Control Plane**: Nodos que ejecutan API Server, Scheduler, Controller Manager y etcd
- **Worker Nodes**: Nodos que ejecutan las cargas de trabajo (pods)
- **etcd**: Base de datos key-value que almacena TODO el estado del cluster
- **CNI**: Container Network Interface, plugins para conectividad de pods
- **HA**: High Availability con múltiples control planes y load balancer

---

## ⚡ Comandos Esenciales

### Instalación y Prerequisites

```bash
# Deshabilitar swap (REQUERIDO)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Módulos del kernel
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Parámetros sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# Instalar containerd
sudo apt-get update
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Instalar kubeadm, kubelet, kubectl
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### Cluster Single Control Plane

```bash
# Inicializar control plane
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --apiserver-advertise-address=<CONTROL_PLANE_IP>

# Configurar kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Instalar CNI (Calico)
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml

# Verificar cluster
kubectl get nodes
kubectl get pods -n kube-system

# Obtener join command
kubeadm token create --print-join-command
```

### Agregar Worker Nodes

```bash
# En cada worker node (después de instalar containerd, kubeadm, kubelet):
sudo kubeadm join <CONTROL_PLANE_IP>:6443 \
  --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH>

# Verificar desde control plane
kubectl get nodes
kubectl label node <worker-name> node-role.kubernetes.io/worker=worker
```

### High Availability (HA)

```bash
# Crear archivo de configuración para HA
cat <<EOF > kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.28.0
controlPlaneEndpoint: "loadbalancer.example.com:6443"
networking:
  podSubnet: "192.168.0.0/16"
apiServer:
  certSANs:
  - "loadbalancer.example.com"
  - "10.0.0.100"
  - "10.0.0.10"
  - "10.0.0.11"
  - "10.0.0.12"
EOF

# Inicializar primer control plane con certs
sudo kubeadm init --config=kubeadm-config.yaml --upload-certs

# Agregar más control planes (usar comando del output anterior)
sudo kubeadm join loadbalancer.example.com:6443 \
  --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH> \
  --control-plane \
  --certificate-key <CERT_KEY>

# Si expira certificate-key, regenerar:
sudo kubeadm init phase upload-certs --upload-certs
```

### Gestión de etcd

```bash
# Verificar salud de etcd
kubectl exec -it -n kube-system etcd-<node-name> -- sh -c \
  "ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health"

# Backup de etcd
sudo ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot-$(date +%Y%m%d).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verificar snapshot
sudo ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-snapshot.db --write-out=table

# Restore de etcd
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sudo ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-restore
# Actualizar /etc/kubernetes/manifests/etcd.yaml con nuevo data-dir
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

# Ver miembros de etcd
kubectl exec -it -n kube-system etcd-<node> -- sh -c \
  "ETCDCTL_API=3 etcdctl member list --write-out=table \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key"
```

### Tokens y Certificados

```bash
# Listar tokens
kubeadm token list

# Crear nuevo token
kubeadm token create

# Crear token con join command
kubeadm token create --print-join-command

# Verificar expiración de certificados
sudo kubeadm certs check-expiration

# Renovar todos los certificados
sudo kubeadm certs renew all
sudo systemctl restart kubelet

# Renovar certificado específico
sudo kubeadm certs renew apiserver
```

### Gestión de Nodos

```bash
# Ver nodos
kubectl get nodes
kubectl get nodes -o wide

# Describir nodo
kubectl describe node <node-name>

# Etiquetar nodo
kubectl label node <node-name> key=value

# Eliminar etiqueta
kubectl label node <node-name> key-

# Cordon (no schedule nuevos pods)
kubectl cordon <node-name>

# Uncordon
kubectl uncordon <node-name>

# Drain (evacuar pods)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Eliminar nodo del cluster
kubectl delete node <node-name>

# Reset en el nodo físico
sudo kubeadm reset
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/etcd/
```

### Troubleshooting

```bash
# Verificar componentes del sistema
kubectl get componentstatuses  # Deprecated pero útil
kubectl get pods -n kube-system

# Ver eventos
kubectl get events -n kube-system --sort-by='.lastTimestamp'

# Logs de kubelet
sudo journalctl -u kubelet -f
sudo journalctl -u kubelet -n 100 --no-pager

# Logs de containerd
sudo journalctl -u containerd -f

# Ver configuración de kubelet
sudo cat /var/lib/kubelet/config.yaml

# Verificar CNI
ls -la /etc/cni/net.d/
cat /etc/cni/net.d/*.conf

# Verificar API Server
kubectl get --raw='/readyz?verbose'
kubectl get --raw='/livez?verbose'
kubectl get --raw='/healthz'

# Verificar certificados
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout

# Ver rutas de red
ip route
sudo iptables -t nat -L -n

# Diagnosticar preflight
sudo kubeadm init phase preflight

# Reset completo
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/etcd/
sudo rm -rf /var/lib/kubelet/
sudo rm -rf /etc/cni/net.d/
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
```

---

## 📊 Puertos Requeridos

### Control Plane

| Puerto | Protocolo | Servicio | Usado Por |
|--------|-----------|----------|-----------|
| 6443 | TCP | API Server | Todos |
| 2379-2380 | TCP | etcd | API Server, etcd |
| 10250 | TCP | Kubelet API | Control plane |
| 10259 | TCP | kube-scheduler | Self |
| 10257 | TCP | kube-controller-manager | Self |

### Worker Nodes

| Puerto | Protocolo | Servicio | Usado Por |
|--------|-----------|----------|-----------|
| 10250 | TCP | Kubelet API | Control plane |
| 30000-32767 | TCP | NodePort Services | Todos |

### Firewall Commands

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 6443/tcp
sudo ufw allow 2379:2380/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 10259/tcp
sudo ufw allow 10257/tcp
sudo ufw allow 30000:32767/tcp

# firewalld (RHEL/CentOS)
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --permanent --add-port=10250/tcp
sudo firewall-cmd --reload
```

---

## 🎯 Workflow de Instalación

```
┌─────────────────────────────────────────┐
│  1. PREREQUISITES                       │
│  ├─ Deshabilitar swap                   │
│  ├─ Módulos kernel (overlay, br_filter)│
│  ├─ Parámetros sysctl                   │
│  └─ Abrir puertos firewall              │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  2. INSTALAR COMPONENTES                │
│  ├─ Container Runtime (containerd)      │
│  ├─ kubeadm                             │
│  ├─ kubelet                             │
│  └─ kubectl                             │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  3. INICIALIZAR CONTROL PLANE           │
│  ├─ kubeadm init                        │
│  ├─ Configurar kubeconfig               │
│  └─ Guardar join command                │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  4. INSTALAR CNI                        │
│  ├─ Calico / Flannel / Weave           │
│  └─ Verificar pods de CNI               │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  5. AGREGAR WORKER NODES                │
│  ├─ kubeadm join en cada worker         │
│  └─ Verificar nodes Ready               │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│  6. VERIFICACIÓN                        │
│  ├─ kubectl get nodes                   │
│  ├─ kubectl get pods -A                 │
│  └─ Deploy test application             │
└─────────────────────────────────────────┘
```

---

## 🔧 Configuraciones Importantes

### kubeadm-config.yaml (Básico)

```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.28.0
networking:
  podSubnet: "192.168.0.0/16"
  serviceSubnet: "10.96.0.0/12"
apiServer:
  extraArgs:
    authorization-mode: "Node,RBAC"
controllerManager:
  extraArgs:
    bind-address: "0.0.0.0"
scheduler:
  extraArgs:
    bind-address: "0.0.0.0"
```

### kubeadm-config.yaml (HA)

```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.28.0
controlPlaneEndpoint: "loadbalancer.example.com:6443"
networking:
  podSubnet: "192.168.0.0/16"
  serviceSubnet: "10.96.0.0/12"
apiServer:
  certSANs:
  - "loadbalancer.example.com"
  - "10.0.0.100"  # VIP
  - "10.0.0.10"   # Control 1
  - "10.0.0.11"   # Control 2
  - "10.0.0.12"   # Control 3
etcd:
  local:
    serverCertSANs:
    - "10.0.0.10"
    - "10.0.0.11"
    - "10.0.0.12"
    peerCertSANs:
    - "10.0.0.10"
    - "10.0.0.11"
    - "10.0.0.12"
```

### HAProxy Config (Load Balancer)

```
frontend kubernetes-frontend
    bind *:6443
    mode tcp
    option tcplog
    default_backend kubernetes-backend

backend kubernetes-backend
    mode tcp
    option tcp-check
    balance roundrobin
    server control-plane-1 10.0.0.10:6443 check
    server control-plane-2 10.0.0.11:6443 check
    server control-plane-3 10.0.0.12:6443 check
```

---

## 🚨 Troubleshooting Rápido

### Problema: Nodo NotReady

```bash
# 1. Ver estado del nodo
kubectl describe node <node-name>

# 2. Verificar kubelet
sudo systemctl status kubelet
sudo journalctl -u kubelet -n 50

# 3. Verificar CNI
kubectl get pods -n kube-system | grep -E 'calico|flannel'

# 4. Reiniciar kubelet
sudo systemctl restart kubelet
```

### Problema: Pod CrashLoopBackOff

```bash
# Ver logs
kubectl logs <pod-name> -n kube-system
kubectl describe pod <pod-name> -n kube-system

# Ver eventos
kubectl get events -n kube-system --sort-by='.lastTimestamp'
```

### Problema: etcd No Saludable

```bash
# Verificar salud
kubectl exec -it -n kube-system etcd-<node> -- sh -c \
  "ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key"

# Ver alarmas
kubectl exec -it -n kube-system etcd-<node> -- sh -c \
  "ETCDCTL_API=3 etcdctl alarm list ..."

# Defragmentar
kubectl exec -it -n kube-system etcd-<node> -- sh -c \
  "ETCDCTL_API=3 etcdctl defrag ..."
```

### Problema: Certificados Expirados

```bash
# Verificar expiración
sudo kubeadm certs check-expiration

# Renovar todos
sudo kubeadm certs renew all
sudo systemctl restart kubelet

# Actualizar kubeconfig
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
```

---

## 📈 Mejores Prácticas

### Producción

- ✅ **HA**: Mínimo 3 control planes (número impar)
- ✅ **Backup etcd**: Automatizado, diario, off-site
- ✅ **Monitoreo**: Prometheus + Grafana
- ✅ **Logging**: ELK/Loki stack
- ✅ **Network Policies**: Habilitar desde inicio
- ✅ **RBAC**: Configurar permisos estrictos
- ✅ **Actualizaciones**: Mantener 2-3 versiones detrás de latest
- ✅ **Documentación**: Procedimientos de DR

### Sizing

**Pequeño** (Dev/Test):
```
1 control plane: 4 vCPU, 8 GB RAM
2-3 workers: 4 vCPU, 8 GB RAM
```

**Mediano** (Staging):
```
3 control planes: 8 vCPU, 16 GB RAM
5-10 workers: 8 vCPU, 16 GB RAM
```

**Grande** (Producción):
```
3+ control planes: 16 vCPU, 32 GB RAM, SSD
20+ workers: 16 vCPU, 32 GB RAM, SSD
```

### Seguridad

```bash
# Deshabilitar acceso público a kubelet
--anonymous-auth=false

# RBAC estricto
kubectl create rolebinding ...

# Network policies
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy

# Pod Security Standards
kubectl label namespace default pod-security.kubernetes.io/enforce=restricted
```

---

## 🎯 Checklist de Instalación

### Control Plane

- [ ] Swap deshabilitado
- [ ] Módulos kernel cargados
- [ ] Parámetros sysctl configurados
- [ ] Firewall configurado (puertos 6443, 2379-2380, 10250, 10259, 10257)
- [ ] Container runtime instalado y corriendo
- [ ] kubeadm, kubelet, kubectl instalados
- [ ] `kubeadm init` ejecutado exitosamente
- [ ] kubeconfig configurado (~/.kube/config)
- [ ] CNI instalado (Calico/Flannel)
- [ ] Control plane node en estado Ready
- [ ] Pods del sistema en Running

### Worker Nodes

- [ ] Swap deshabilitado
- [ ] Módulos kernel cargados
- [ ] Parámetros sysctl configurados
- [ ] Firewall configurado (puerto 10250, 30000-32767)
- [ ] Container runtime instalado y corriendo
- [ ] kubeadm, kubelet instalados
- [ ] `kubeadm join` ejecutado exitosamente
- [ ] Nodo en estado Ready
- [ ] Pods del sistema (kube-proxy, CNI) en Running

### HA (Adicional)

- [ ] Load balancer configurado y testeado
- [ ] DNS/VIP apuntando al load balancer
- [ ] Primer control plane inicializado con `--upload-certs`
- [ ] Certificados SAN incluyen LB y todos los control planes
- [ ] Adicionales control planes joined con `--control-plane`
- [ ] etcd cluster saludable (3+ miembros)
- [ ] Failover testeado (apagar un control plane)

### Backup

- [ ] Script de backup de etcd creado
- [ ] Backup automatizado (cron)
- [ ] Backup storage off-site configurado
- [ ] Procedimiento de restore documentado
- [ ] Restore testeado en cluster de prueba

---

## 📚 Variables de Entorno Útiles

```bash
# KUBECONFIG
export KUBECONFIG=/etc/kubernetes/admin.conf
export KUBECONFIG=$HOME/.kube/config

# etcd
export ETCDCTL_API=3
export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key
export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379

# Simplificar comandos etcd
alias etcdctl='ETCDCTL_API=3 etcdctl \
  --endpoints=$ETCDCTL_ENDPOINTS \
  --cacert=$ETCDCTL_CACERT \
  --cert=$ETCDCTL_CERT \
  --key=$ETCDCTL_KEY'
```

---

## 🔗 Referencias Rápidas

- [kubeadm Docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [CNI Plugins](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)
- [etcd Docs](https://etcd.io/docs/)
- [Calico Docs](https://docs.tigera.io/calico/latest/about/)

---

## ⏭️ Próximos Pasos

- **Laboratorios**: Practicar instalación hands-on
- **Módulo 23**: Maintenance & Upgrades
- **Módulo 26**: Troubleshooting Avanzado

---

**Nota**: Este resumen cubre los comandos más importantes. Para explicaciones detalladas, consultar [README.md](./README.md).
