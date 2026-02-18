# Lab 02: Cluster High Availability (HA) con kubeadm

**Duración estimada:** 90-120 minutos  
**Dificultad:** ⭐⭐⭐⭐ Avanzado

## 🎯 Objetivos

Al completar este laboratorio, serás capaz de:
- ✅ Configurar un cluster HA con 3 control planes
- ✅ Implementar un load balancer para API server
- ✅ Entender topología stacked vs external etcd
- ✅ Validar failover de control plane
- ✅ Gestionar certificados en entorno HA

## 🏗️ Arquitectura HA

```
                    ┌───────────────────┐
                    │   Load Balancer   │
                    │   (HAProxy/nginx) │
                    │  192.168.1.100    │
                    │    Port: 6443     │
                    └────────┬──────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼──────────┐ ┌──────▼────────┐ ┌────────▼───────┐
│  Control Plane 1 │ │ Control Plane │ │ Control Plane  │
│  k8s-master-01   │ │ k8s-master-02 │ │ k8s-master-03  │
│  192.168.1.10    │ │ 192.168.1.11  │ │ 192.168.1.12   │
│                  │ │               │ │                │
│  ┌────────────┐  │ │ ┌──────────┐  │ │ ┌────────────┐ │
│  │ API Server │  │ │ │API Server│  │ │ │ API Server │ │
│  │ Controller │  │ │ │Controller│  │ │ │ Controller │ │
│  │ Scheduler  │  │ │ │Scheduler │  │ │ │ Scheduler  │ │
│  │    etcd    │◄─┼─┼►│   etcd   │◄─┼─┼►│    etcd    │ │
│  └────────────┘  │ │ └──────────┘  │ │ └────────────┘ │
└──────────────────┘ └───────────────┘ └────────────────┘
        │                    │                    │
        └────────────────────┼────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
┌───────▼──────────┐ ┌──────▼────────┐ ┌────────▼───────┐
│  k8s-worker-01   │ │ k8s-worker-02 │ │ k8s-worker-03  │
│  192.168.1.20    │ │ 192.168.1.21  │ │ 192.168.1.22   │
│                  │ │               │ │                │
│  - kubelet       │ │ - kubelet     │ │ - kubelet      │
│  - kube-proxy    │ │ - kube-proxy  │ │ - kube-proxy   │
│  - containerd    │ │ - containerd  │ │ - containerd   │
└──────────────────┘ └───────────────┘ └────────────────┘
```

## 📋 Prerequisites

### Hardware
- **Load Balancer**: 1 CPU, 1GB RAM, 10GB disk
- **Control Planes (3x)**: 2 CPU, 2GB RAM, 20GB disk cada uno
- **Workers (3x)**: 2 CPU, 2GB RAM, 20GB disk cada uno

**Total: 7 VMs**

### Software
- Ubuntu 22.04 LTS (recomendado)
- HAProxy 2.4+ o nginx 1.20+ (para load balancer)
- Acceso root (sudo) en todos los nodos

### Preparación de Red

```bash
# Configurar /etc/hosts en TODOS los nodos
sudo tee -a /etc/hosts <<EOF
192.168.1.100 k8s-lb k8s-lb.example.com
192.168.1.10  k8s-master-01
192.168.1.11  k8s-master-02
192.168.1.12  k8s-master-03
192.168.1.20  k8s-worker-01
192.168.1.21  k8s-worker-02
192.168.1.22  k8s-worker-03
EOF

# Configurar hostnames
# En load balancer:
sudo hostnamectl set-hostname k8s-lb

# En cada master:
sudo hostnamectl set-hostname k8s-master-01  # En master-01
sudo hostnamectl set-hostname k8s-master-02  # En master-02
sudo hostnamectl set-hostname k8s-master-03  # En master-03

# En cada worker:
sudo hostnamectl set-hostname k8s-worker-01  # En worker-01
sudo hostnamectl set-hostname k8s-worker-02  # En worker-02
sudo hostnamectl set-hostname k8s-worker-03  # En worker-03

# Verificar conectividad desde cualquier nodo
ping -c 2 k8s-lb
ping -c 2 k8s-master-01
ping -c 2 k8s-master-02
ping -c 2 k8s-master-03
```

---

## 🔧 Paso 1: Configurar Load Balancer (HAProxy)

### 1.1 Instalar HAProxy

En el nodo **k8s-lb** (192.168.1.100):

```bash
# Instalar HAProxy
sudo apt-get update
sudo apt-get install -y haproxy

# Verificar instalación
haproxy -v
```

### 1.2 Configurar HAProxy

```bash
# Backup de configuración original
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup

# Crear nueva configuración
sudo tee /etc/haproxy/haproxy.cfg <<EOF
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # Security
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # Default SSL material locations
    ssl-default-bind-ciphers ECDHE+AESGCM:ECDHE+AES256:ECDHE+AES128:!SSLv3:!TLSv1
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

# Stats page (opcional pero útil)
listen stats
    bind :8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats realm HAProxy\ Statistics
    stats auth admin:admin123  # Cambiar en producción

# Frontend para Kubernetes API Server
frontend kubernetes-api
    bind *:6443
    mode tcp
    option tcplog
    default_backend kubernetes-api-backend

# Backend para los 3 control planes
backend kubernetes-api-backend
    mode tcp
    option tcp-check
    balance roundrobin
    # Health check: TCP connection
    server master-01 192.168.1.10:6443 check fall 3 rise 2
    server master-02 192.168.1.11:6443 check fall 3 rise 2
    server master-03 192.168.1.12:6443 check fall 3 rise 2
EOF
```

### 1.3 Habilitar y Verificar HAProxy

```bash
# Verificar sintaxis
sudo haproxy -c -f /etc/haproxy/haproxy.cfg

# Reiniciar HAProxy
sudo systemctl restart haproxy
sudo systemctl enable haproxy

# Verificar estado
sudo systemctl status haproxy

# Ver logs en tiempo real
sudo journalctl -u haproxy -f
```

### 1.4 Verificar Load Balancer

```bash
# Verificar que puerto 6443 está escuchando
sudo ss -tlnp | grep 6443

# Acceder a stats page (desde navegador o curl)
curl http://192.168.1.100:8404/stats

# O desde navegador: http://192.168.1.100:8404/stats
# Usuario: admin, Contraseña: admin123
```

**✅ Checkpoint**: HAProxy en estado **active (running)**.

---

## 🚀 Paso 2: Instalar Prerequisites (Todos los nodos K8s)

En **TODOS los control planes y workers** (NO en el load balancer):

```bash
# Usar script de instalación (ver Lab 01)
chmod +x ../scripts/install-prerequisites.sh
sudo ../scripts/install-prerequisites.sh

# O instalación manual (ver Lab 01 para detalles)
```

**Verificar en cada nodo:**
```bash
kubeadm version
kubelet --version
kubectl version --client
sudo systemctl status containerd
free -h  # Swap debe ser 0
```

---

## 🎮 Paso 3: Inicializar PRIMER Control Plane

### 3.1 Preparar Configuración

En **k8s-master-01** (192.168.1.10):

```bash
# Crear configuración kubeadm para HA
cat <<EOF > kubeadm-ha-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 192.168.1.10
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
  name: k8s-master-01
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/control-plane
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.28.0
clusterName: ha-production-cluster
# ⚠️ CRITICAL: Load balancer endpoint
controlPlaneEndpoint: "k8s-lb.example.com:6443"
networking:
  dnsDomain: cluster.local
  podSubnet: 192.168.0.0/16
  serviceSubnet: 10.96.0.0/12
apiServer:
  certSANs:
  - "k8s-lb.example.com"
  - "k8s-lb"
  - "192.168.1.100"
  - "k8s-master-01"
  - "192.168.1.10"
  - "k8s-master-02"
  - "192.168.1.11"
  - "k8s-master-03"
  - "192.168.1.12"
  - "127.0.0.1"
  extraArgs:
    authorization-mode: "Node,RBAC"
controllerManager:
  extraArgs:
    leader-elect: "true"
scheduler:
  extraArgs:
    leader-elect: "true"
etcd:
  local:
    dataDir: /var/lib/etcd
    extraArgs:
      listen-client-urls: "https://127.0.0.1:2379,https://192.168.1.10:2379"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF
```

### 3.2 Inicializar con --upload-certs

```bash
# Inicializar primer control plane con upload de certificados
sudo kubeadm init --config kubeadm-ha-config.yaml --upload-certs

# ⚠️ GUARDAR OUTPUT COMPLETO
# Necesitarás:
# 1. certificate-key (para masters adicionales)
# 2. control-plane join command
# 3. worker join command
```

**Output esperado:**
```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You can now join any number of control-plane nodes by running:

  kubeadm join k8s-lb.example.com:6443 --token abc123.xyz789 \
    --discovery-token-ca-cert-hash sha256:1234567890abcdef... \
    --control-plane --certificate-key fedcba0987654321...

Please note that the certificate-key above is confidential!

Then you can join any number of worker nodes by running:

  kubeadm join k8s-lb.example.com:6443 --token abc123.xyz789 \
    --discovery-token-ca-cert-hash sha256:1234567890abcdef...
```

### 3.3 Configurar kubectl

```bash
# En k8s-master-01
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verificar acceso
kubectl cluster-info
kubectl get nodes
```

### 3.4 Instalar CNI (Calico)

```bash
# Instalar Calico
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Esperar a que Calico esté Ready
watch kubectl get pods -n kube-system

# Verificar nodo Ready
kubectl get nodes
```

**✅ Checkpoint**: k8s-master-01 en estado **Ready**.

---

## 🔄 Paso 4: Agregar Control Planes Adicionales

### 4.1 Unir Segundo Control Plane (k8s-master-02)

En **k8s-master-02** (192.168.1.11):

```bash
# Usar join command del output anterior
# MODIFICAR advertiseAddress para este nodo

sudo kubeadm join k8s-lb.example.com:6443 \
  --token abc123.xyz789 \
  --discovery-token-ca-cert-hash sha256:1234567890abcdef... \
  --control-plane \
  --certificate-key fedcba0987654321... \
  --apiserver-advertise-address=192.168.1.11
```

**Output esperado:**
```
This node has joined the cluster and a new control plane instance was created
```

### 4.2 Unir Tercer Control Plane (k8s-master-03)

En **k8s-master-03** (192.168.1.12):

```bash
sudo kubeadm join k8s-lb.example.com:6443 \
  --token abc123.xyz789 \
  --discovery-token-ca-cert-hash sha256:1234567890abcdef... \
  --control-plane \
  --certificate-key fedcba0987654321... \
  --apiserver-advertise-address=192.168.1.12
```

### 4.3 Configurar kubectl en Masters Adicionales

En **k8s-master-02** y **k8s-master-03**:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verificar
kubectl get nodes
```

### 4.4 Verificar HA Control Plane

Desde **cualquier master**:

```bash
# Ver todos los control planes
kubectl get nodes -o wide

# Ver endpoints del API server
kubectl get endpoints -n kube-system

# Ver pods de etcd (debe haber 3)
kubectl get pods -n kube-system -l component=etcd

# Ver estado de etcd
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list

# Ver salud de etcd
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
```

**Salida esperada:**
- 3 nodos con role `control-plane`
- 3 miembros de etcd listados
- 3 endpoints saludables

**✅ Checkpoint**: 3 control planes en **Ready**, etcd con 3 miembros **healthy**.

---

## 👷 Paso 5: Agregar Worker Nodes

### 5.1 Unir Workers al Cluster

En **CADA worker** (k8s-worker-01, k8s-worker-02, k8s-worker-03):

```bash
# Usar worker join command del output de kubeadm init
sudo kubeadm join k8s-lb.example.com:6443 \
  --token abc123.xyz789 \
  --discovery-token-ca-cert-hash sha256:1234567890abcdef...
```

### 5.2 Verificar Workers

Desde **cualquier master**:

```bash
# Ver todos los nodos (3 masters + 3 workers = 6 nodos)
kubectl get nodes -o wide

# Etiquetar workers (opcional)
kubectl label node k8s-worker-01 node-role.kubernetes.io/worker=worker
kubectl label node k8s-worker-02 node-role.kubernetes.io/worker=worker
kubectl label node k8s-worker-03 node-role.kubernetes.io/worker=worker

# Ver nodos con labels
kubectl get nodes
```

**Salida esperada:**
```
NAME            STATUS   ROLES           AGE   VERSION
k8s-master-01   Ready    control-plane   20m   v1.28.0
k8s-master-02   Ready    control-plane   15m   v1.28.0
k8s-master-03   Ready    control-plane   10m   v1.28.0
k8s-worker-01   Ready    worker          5m    v1.28.0
k8s-worker-02   Ready    worker          5m    v1.28.0
k8s-worker-03   Ready    worker          5m    v1.28.0
```

**✅ Checkpoint**: 6 nodos en estado **Ready** (3 control-plane, 3 worker).

---

## 🧪 Paso 6: Test de High Availability

### 6.1 Verificar Leader Election

```bash
# Ver quién es el leader del controller-manager
kubectl get endpoints -n kube-system kube-controller-manager -o yaml

# Ver quién es el leader del scheduler
kubectl get endpoints -n kube-system kube-scheduler -o yaml

# Logs del controller-manager leader
kubectl logs -n kube-system -l component=kube-controller-manager | grep leader
```

### 6.2 Test de Failover - Apagar Master

```bash
# En k8s-master-01, apagar el nodo
sudo shutdown -h now

# O simular fallo de red
sudo iptables -A INPUT -p tcp --dport 6443 -j DROP
```

**Desde otro master (k8s-master-02 o k8s-master-03):**

```bash
# Verificar que el cluster sigue funcionando
kubectl get nodes

# Ver HAProxy stats
curl http://192.168.1.100:8404/stats

# Crear deployment de prueba
kubectl create deployment test-failover --image=nginx --replicas=3
kubectl get pods -o wide

# El cluster DEBE seguir funcionando!
```

### 6.3 Recuperar Master Fallido

```bash
# Encender k8s-master-01 nuevamente
# O restaurar red:
sudo iptables -D INPUT -p tcp --dport 6443 -j DROP

# Verificar que se reincorpora al cluster
kubectl get nodes
kubectl get pods -n kube-system -o wide | grep master-01
```

### 6.4 Test de etcd Quorum

```bash
# Ver estado del quorum
kubectl exec -n kube-system etcd-k8s-master-01 -- \
  etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  member list -w table

# Crear dato de prueba
kubectl create configmap test-ha --from-literal=key=value

# Apagar 1 master (cluster debe seguir funcionando)
# Apagar 2 masters (cluster pierde quorum y deja de funcionar)
```

**⚠️ IMPORTANTE**: 
- Con 3 nodos etcd, puedes perder **1 nodo** y mantener quorum
- Si pierdes **2 nodos**, pierdes quorum (mayoría = 2/3)
- Por eso se recomienda **número impar** de control planes (3, 5, 7)

---

## 📊 Paso 7: Validaciones Finales HA

### Checklist de Validación HA

```bash
# ✅ 1. Todos los nodos Ready (3 masters + 3 workers)
kubectl get nodes
# Esperado: 6 nodos, STATUS=Ready

# ✅ 2. Load Balancer distribuyendo tráfico
curl -k https://k8s-lb.example.com:6443/healthz
# Esperado: ok

# ✅ 3. Tres instancias de cada componente control plane
kubectl get pods -n kube-system -o wide | grep -E "(apiserver|controller|scheduler|etcd)"
# Esperado: 3 de cada uno

# ✅ 4. etcd cluster con 3 miembros
kubectl exec -n kube-system etcd-k8s-master-01 -- \
  etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/peer.crt \
  --key=/etc/kubernetes/pki/etcd/peer.key \
  member list
# Esperado: 3 miembros

# ✅ 5. Leader election funcionando
kubectl get endpoints -n kube-system kube-controller-manager -o jsonpath='{.metadata.annotations.control-plane\.alpha\.kubernetes\.io/leader}'
# Esperado: JSON con leader actual

# ✅ 6. Workloads distribuidos en workers
kubectl create deployment test-ha --image=nginx --replicas=6
kubectl get pods -o wide
kubectl delete deployment test-ha
# Esperado: Pods en diferentes workers

# ✅ 7. Failover funciona (apagar 1 master)
# Ver test anterior
```

---

## 🎓 Desafíos Opcionales

### Desafío 1: Agregar 4to Control Plane

```bash
# Generar nuevo token y certificate-key
sudo kubeadm init phase upload-certs --upload-certs
kubeadm token create --print-join-command

# Agregar k8s-master-04
# Nota: 4 nodos no es recomendado (usar impar), pero funcional
```

### Desafío 2: Configurar External etcd

Separar etcd en su propio cluster (topología más compleja pero más resiliente).

Ver: [External etcd topology](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/#external-etcd-topology)

### Desafío 3: Implementar Backup Automático de etcd

```bash
# Configurar cron job para backup de etcd
sudo crontab -e

# Agregar línea (backup cada 6 horas)
0 */6 * * * /path/to/etcd-backup.sh backup >> /var/log/etcd-backup.log 2>&1
```

---

## 🧹 Limpieza

```bash
# En CADA nodo (masters y workers)
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo rm -rf $HOME/.kube
sudo rm -rf /var/lib/etcd

# En load balancer
sudo systemctl stop haproxy
sudo apt-get purge -y haproxy
```

---

## 🐛 Troubleshooting HA

### Problema: Master no se une al cluster

```bash
# Verificar que load balancer es accesible
telnet k8s-lb.example.com 6443

# Verificar logs de kubeadm
sudo journalctl -u kubelet -f

# Regenerar certificate-key si expiró (expira en 2 horas)
sudo kubeadm init phase upload-certs --upload-certs --config kubeadm-ha-config.yaml
```

### Problema: etcd no forma quorum

```bash
# Ver logs de etcd
kubectl logs -n kube-system etcd-k8s-master-01

# Verificar conectividad entre masters (puerto 2380)
telnet k8s-master-02 2380

# Ver estado de peers
sudo etcdctl member list
```

### Problema: HAProxy backends DOWN

```bash
# Ver stats de HAProxy
curl http://192.168.1.100:8404/stats

# Verificar que API servers están escuchando
sudo ss -tlnp | grep 6443

# Probar conectividad directa a cada master
curl -k https://k8s-master-01:6443/healthz
curl -k https://k8s-master-02:6443/healthz
curl -k https://k8s-master-03:6443/healthz
```

---

## 📚 Recursos Adicionales

- [HA Kubernetes Clusters](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/)
- [etcd FAQ](https://etcd.io/docs/v3.5/faq/)
- [HAProxy Configuration Manual](https://www.haproxy.org/download/2.4/doc/configuration.txt)

---

## ✅ Criterios de Completitud

Has completado exitosamente este lab si:
- [ ] 3 control planes en estado Ready
- [ ] 3 workers en estado Ready
- [ ] Load balancer distribuyendo tráfico a los 3 masters
- [ ] etcd cluster con 3 miembros healthy
- [ ] Leader election funcionando (controller-manager, scheduler)
- [ ] Cluster sobrevive a la caída de 1 control plane
- [ ] Pods se pueden crear y ejecutar normalmente

**¡Felicitaciones!** 🎉 Tienes un cluster HA production-ready.

**Próximo paso:** [Lab 03: Backup y Restore de etcd](./lab-03-etcd-backup-restore.md)
