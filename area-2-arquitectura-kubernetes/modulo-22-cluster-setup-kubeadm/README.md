# Módulo 22: Cluster Setup con kubeadm

## 📋 Información del Módulo

| Atributo | Detalle |
|----------|---------|
| **Duración estimada** | 2.5 horas |
| **Nivel** | 🔴 Avanzado |
| **Prerequisitos** | Módulos 1-21, Linux básico, Networking básico |
| **Objetivos de aprendizaje** | Instalar y configurar clusters Kubernetes con kubeadm |
| **Certificación** | CKA (25% del examen) |
| **Laboratorios** | 4 labs prácticos |

---

## 🎯 Objetivos de Aprendizaje

Al completar este módulo, serás capaz de:

- ✅ **Instalar** un cluster Kubernetes desde cero con kubeadm
- ✅ **Configurar** control plane y worker nodes
- ✅ **Implementar** clusters High Availability (HA)
- ✅ **Gestionar** etcd y realizar backup/restore
- ✅ **Configurar** networking con CNI plugins
- ✅ **Troubleshootear** problemas comunes de instalación
- ✅ **Escalar** clusters agregando/removiendo nodos
- ✅ **Actualizar** versiones de Kubernetes

---

## 📚 Contenido

1. [Introducción a kubeadm](#1-introducción-a-kubeadm)
2. [Prerequisites del Sistema](#2-prerequisites-del-sistema)
3. [Instalación de Componentes](#3-instalación-de-componentes)
4. [Inicializar Control Plane](#4-inicializar-control-plane)
5. [Configurar Networking (CNI)](#5-configurar-networking-cni)
6. [Agregar Worker Nodes](#6-agregar-worker-nodes)
7. [High Availability (HA)](#7-high-availability-ha)
8. [Gestión de etcd](#8-gestión-de-etcd)
9. [Troubleshooting](#9-troubleshooting)
10. [Mejores Prácticas](#10-mejores-prácticas)

---

## 1. Introducción a kubeadm

### ¿Qué es kubeadm?

`kubeadm` es la herramienta oficial de Kubernetes para:
- ✅ Inicializar clusters Kubernetes
- ✅ Realizar bootstrapping de control plane
- ✅ Gestionar certificados y configuraciones
- ✅ Facilitar upgrades de clusters
- ✅ Seguir mejores prácticas de Kubernetes

### kubeadm vs Otras Herramientas

| Herramienta | Caso de Uso | Complejidad | Producción |
|-------------|-------------|-------------|------------|
| **kubeadm** | Clusters on-premises, VMs | Media | ✅ Sí |
| **Minikube** | Desarrollo local | Baja | ❌ No |
| **Kind** | Testing, CI/CD | Baja | ❌ No |
| **kops** | AWS principalmente | Alta | ✅ Sí |
| **Kubespray** | Ansible-based, multi-cloud | Alta | ✅ Sí |
| **Managed** (AKS, EKS, GKE) | Cloud-native | Baja | ✅ Sí |

### Arquitectura de Cluster con kubeadm

```
┌─────────────────────────────────────────────────────────────┐
│                    CONTROL PLANE NODE(S)                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ API Server  │  │  Scheduler  │  │ Controller  │        │
│  │             │  │             │  │   Manager   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                             │
│  ┌─────────────────────────────────────────────────┐       │
│  │               etcd (key-value store)            │       │
│  └─────────────────────────────────────────────────┘       │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │  kubelet  │  kube-proxy  │  Container Runtime (CRI) │ │
│  └───────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Network (CNI)
                            │
┌────────────────────────────┴──────────────────────────────┐
│                    WORKER NODES                            │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  Node 1                                             │  │
│  │  ┌─────────┐  ┌──────────┐  ┌──────────────────┐   │  │
│  │  │ kubelet │  │kube-proxy│  │ Container Runtime│   │  │
│  │  └─────────┘  └──────────┘  └──────────────────┘   │  │
│  │  ┌─────────────────────────────────────────────┐   │  │
│  │  │         Application Pods                    │   │  │
│  │  └─────────────────────────────────────────────┘   │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                            │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  Node 2, Node 3, ... (Similar structure)          │  │
│  └─────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
```

### Workflow de Instalación

```
1. Prerequisites
   ├── Sistema operativo compatible
   ├── Recursos mínimos (CPU, RAM, Disk)
   ├── Networking configurado
   └── Puertos abiertos

2. Instalación de Componentes
   ├── Container Runtime (containerd/CRI-O)
   ├── kubeadm
   ├── kubelet
   └── kubectl

3. Inicializar Control Plane
   ├── kubeadm init
   ├── Configurar kubeconfig
   └── Verificar componentes

4. Instalar CNI Plugin
   ├── Calico / Flannel / Weave
   └── Verificar networking

5. Agregar Worker Nodes
   ├── kubeadm join (con token)
   └── Verificar nodos

6. Validación Final
   ├── kubectl get nodes
   ├── kubectl get pods -A
   └── Deploy test application
```

---

## 2. Prerequisites del Sistema

### Requisitos de Hardware

#### Control Plane Node

| Recurso | Mínimo | Recomendado | Producción HA |
|---------|--------|-------------|---------------|
| **CPU** | 2 cores | 4 cores | 8+ cores |
| **RAM** | 2 GB | 4 GB | 16+ GB |
| **Disk** | 20 GB | 50 GB | 100+ GB SSD |
| **Network** | 1 Gbps | 10 Gbps | 10+ Gbps |

#### Worker Nodes

| Recurso | Mínimo | Recomendado | Producción |
|---------|--------|-------------|------------|
| **CPU** | 1 core | 2 cores | 4+ cores |
| **RAM** | 1 GB | 2 GB | 8+ GB |
| **Disk** | 10 GB | 20 GB | 50+ GB |
| **Network** | 1 Gbps | 10 Gbps | 10+ Gbps |

### Requisitos de Sistema Operativo

**Soportados**:
- ✅ Ubuntu 20.04/22.04 LTS
- ✅ Debian 10/11
- ✅ CentOS/RHEL 8/9
- ✅ Rocky Linux 8/9
- ✅ Fedora 36+

**Kernel**:
- Mínimo: 4.x
- Recomendado: 5.x+

### Configuración de Red

#### Puertos Requeridos

**Control Plane**:
```
6443        TCP  API Server
2379-2380   TCP  etcd server client API
10250       TCP  Kubelet API
10259       TCP  kube-scheduler
10257       TCP  kube-controller-manager
```

**Worker Nodes**:
```
10250       TCP  Kubelet API
30000-32767 TCP  NodePort Services
```

**etcd (solo para HA)**:
```
2379-2380   TCP  Client requests
2380        TCP  Peer communication
```

#### Verificar Puertos

```bash
# En cada nodo
nc -zv <control-plane-ip> 6443
nc -zv <control-plane-ip> 2379
nc -zv <control-plane-ip> 10250

# O usar nmap
nmap -p 6443,2379-2380,10250,10259,10257 <control-plane-ip>
```

### Deshabilitar Swap

**¿Por qué?**
- Kubernetes requiere swap deshabilitado para garantizar rendimiento predecible
- kubelet no inicia si swap está habilitado

```bash
# Verificar swap
free -h
swapon --show

# Deshabilitar temporalmente
sudo swapoff -a

# Deshabilitar permanentemente
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Verificar
free -h  # Swap debe mostrar 0
```

### Configurar Firewall

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
sudo firewall-cmd --permanent --add-port=10259/tcp
sudo firewall-cmd --permanent --add-port=10257/tcp
sudo firewall-cmd --permanent --add-port=30000-32767/tcp
sudo firewall-cmd --reload

# O deshabilitar firewall (NO recomendado para producción)
sudo systemctl stop firewalld
sudo systemctl disable firewalld
```

### Configurar SELinux (RHEL/CentOS)

```bash
# Opción 1: Permissive mode (recomendado para desarrollo)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Opción 2: Disabled (NO recomendado para producción)
# sudo sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
# sudo reboot

# Verificar
getenforce  # Debe mostrar Permissive o Disabled
```

### Configurar Módulos del Kernel

```bash
# Cargar módulos necesarios
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Verificar
lsmod | grep br_netfilter
lsmod | grep overlay
```

### Configurar Parámetros Sysctl

```bash
# Configuración de red para Kubernetes
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Aplicar cambios sin reiniciar
sudo sysctl --system

# Verificar
sudo sysctl net.bridge.bridge-nf-call-iptables net.ipv4.ip_forward
```

---

## 3. Instalación de Componentes

### Paso 1: Instalar Container Runtime

Kubernetes requiere un Container Runtime compatible con CRI (Container Runtime Interface).

#### Opción A: containerd (Recomendado)

```bash
# Actualizar sistema
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# Instalar containerd
sudo apt-get install -y containerd

# Configurar containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Habilitar SystemdCgroup (CRÍTICO)
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Reiniciar containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# Verificar
sudo systemctl status containerd
```

#### Opción B: CRI-O

```bash
# Configurar repositorio CRI-O
export OS=xUbuntu_22.04
export VERSION=1.28

echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" | \
  sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list

echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" | \
  sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | \
  sudo apt-key add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | \
  sudo apt-key add -

# Instalar CRI-O
sudo apt-get update
sudo apt-get install -y cri-o cri-o-runc

# Iniciar CRI-O
sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl start crio

# Verificar
sudo systemctl status crio
```

### Paso 2: Instalar kubeadm, kubelet y kubectl

```bash
# Agregar repositorio de Kubernetes
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

sudo mkdir -p -m 755 /etc/apt/keyrings

# Agregar GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Agregar repositorio
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

# Instalar componentes
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# Prevenir actualizaciones automáticas
sudo apt-mark hold kubelet kubeadm kubectl

# Habilitar kubelet
sudo systemctl enable --now kubelet

# Verificar versiones
kubeadm version
kubelet --version
kubectl version --client
```

### Paso 3: Verificar Instalación

```bash
# Verificar que todos los componentes están instalados
which kubeadm kubelet kubectl
# Debe mostrar rutas: /usr/bin/kubeadm, /usr/bin/kubelet, /usr/bin/kubectl

# Verificar Container Runtime
crictl --version  # Para containerd/CRI-O

# Verificar prerequisitos de kubeadm
sudo kubeadm init phase preflight
```

---

## 4. Inicializar Control Plane

### Comando Básico

```bash
# En el nodo control plane
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --apiserver-advertise-address=<CONTROL_PLANE_IP>

# Ejemplo:
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --apiserver-advertise-address=10.0.0.10
```

### Parámetros Importantes

| Parámetro | Descripción | Ejemplo |
|-----------|-------------|---------|
| `--pod-network-cidr` | CIDR para pods | `192.168.0.0/16` (Calico), `10.244.0.0/16` (Flannel) |
| `--apiserver-advertise-address` | IP del API Server | `10.0.0.10` |
| `--control-plane-endpoint` | Endpoint para HA | `loadbalancer.example.com:6443` |
| `--kubernetes-version` | Versión específica | `v1.28.0` |
| `--upload-certs` | Subir certs para HA | (flag sin valor) |
| `--config` | Archivo de configuración | `kubeadm-config.yaml` |

### Output Esperado

```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.0.0.10:6443 --token abc123.xyz789 \
    --discovery-token-ca-cert-hash sha256:1234567890abcdef...
```

### Configurar kubectl

```bash
# Como usuario regular (recomendado)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Como root (NO recomendado para uso regular)
export KUBECONFIG=/etc/kubernetes/admin.conf

# Verificar
kubectl cluster-info
kubectl get nodes
```

### Guardar Join Command

```bash
# El comando join se muestra al final de kubeadm init
# IMPORTANTE: Guardar este comando en un lugar seguro

# Si perdiste el comando, puedes regenerarlo:
kubeadm token create --print-join-command
```

### Componentes del Control Plane

Después de `kubeadm init`, estos pods se crean automáticamente:

```bash
kubectl get pods -n kube-system

# Pods esperados:
# - kube-apiserver-<hostname>
# - kube-controller-manager-<hostname>
# - kube-scheduler-<hostname>
# - etcd-<hostname>
# - kube-proxy-<random>
# - coredns-<random> (2 réplicas)
```

### Archivos de Configuración Generados

```bash
/etc/kubernetes/
├── admin.conf              # Kubeconfig para admin
├── kubelet.conf            # Config del kubelet
├── controller-manager.conf # Config del controller manager
├── scheduler.conf          # Config del scheduler
├── manifests/              # Static pod manifests
│   ├── kube-apiserver.yaml
│   ├── kube-controller-manager.yaml
│   ├── kube-scheduler.yaml
│   └── etcd.yaml
└── pki/                    # Certificados y claves
    ├── ca.crt
    ├── ca.key
    ├── apiserver.crt
    ├── apiserver.key
    └── ... (más certificados)
```

---

## 5. Configurar Networking (CNI)

### ¿Qué es un CNI Plugin?

Container Network Interface (CNI) plugins proveen:
- ✅ Conectividad entre pods
- ✅ Asignación de IPs
- ✅ Network policies
- ✅ Service discovery

### Opciones de CNI

| Plugin | Complejidad | Network Policies | IPAM | Mejor Para |
|--------|-------------|------------------|------|------------|
| **Calico** | Media | ✅ Sí | ✅ Sí | Producción, seguridad |
| **Flannel** | Baja | ❌ No | ⚠️ Básico | Desarrollo, simple |
| **Weave** | Baja | ✅ Sí | ✅ Sí | Multi-cloud |
| **Cilium** | Alta | ✅ Sí (eBPF) | ✅ Sí | Avanzado, eBPF |

### Instalar Calico (Recomendado)

```bash
# Aplicar manifest de Calico
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml

# Verificar pods de Calico
kubectl get pods -n kube-system | grep calico

# Output esperado:
# calico-kube-controllers-...  1/1   Running
# calico-node-...              1/1   Running (uno por nodo)

# Esperar a que todos los pods estén Running
kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=300s
```

### Instalar Flannel

```bash
# Aplicar manifest de Flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Verificar
kubectl get pods -n kube-flannel
```

### Verificar Networking

```bash
# 1. Verificar que el control plane node está Ready
kubectl get nodes
# Debe mostrar: STATUS = Ready

# 2. Verificar pods de CNI
kubectl get pods -n kube-system -l k8s-app=calico-node

# 3. Verificar CIDR de pods
kubectl cluster-info dump | grep -i cidr

# 4. Test de conectividad básico
kubectl run test-pod --image=nginx
kubectl wait --for=condition=Ready pod/test-pod --timeout=60s
kubectl get pod test-pod -o wide  # Ver IP asignada
kubectl delete pod test-pod
```

---

## 6. Agregar Worker Nodes

### Preparar Worker Nodes

En cada worker node, realizar los pasos 1-3 de [Instalación de Componentes](#3-instalación-de-componentes):
1. Instalar Container Runtime
2. Instalar kubeadm, kubelet, kubectl
3. Configurar prerequisites

### Obtener Join Command

**Opción 1: Usar el comando generado en `kubeadm init`**

```bash
# El comando mostrado al final de kubeadm init:
kubeadm join 10.0.0.10:6443 --token abc123.xyz789 \
    --discovery-token-ca-cert-hash sha256:1234567890abcdef...
```

**Opción 2: Regenerar token**

```bash
# En el control plane
kubeadm token create --print-join-command

# Output:
# kubeadm join 10.0.0.10:6443 --token newtoken.xyz123 \
#     --discovery-token-ca-cert-hash sha256:newhash...
```

### Ejecutar Join en Worker Node

```bash
# En el worker node, como root:
sudo kubeadm join 10.0.0.10:6443 \
  --token abc123.xyz789 \
  --discovery-token-ca-cert-hash sha256:1234567890abcdef...

# Output esperado:
# This node has joined the cluster:
# * Certificate signing request was sent to apiserver and a response was received.
# * The Kubelet was informed of the new secure connection details.
```

### Verificar Nodo Agregado

```bash
# En el control plane
kubectl get nodes

# Output:
# NAME               STATUS   ROLES           AGE   VERSION
# control-plane      Ready    control-plane   10m   v1.28.0
# worker-node-1      Ready    <none>          2m    v1.28.0

# Ver detalles del nodo
kubectl describe node worker-node-1

# Ver pods del sistema en el nodo
kubectl get pods -n kube-system -o wide | grep worker-node-1
```

### Etiquetar Worker Nodes

```bash
# Agregar label de rol (opcional, cosmético)
kubectl label node worker-node-1 node-role.kubernetes.io/worker=worker

# Agregar labels personalizados
kubectl label node worker-node-1 environment=production
kubectl label node worker-node-1 disk=ssd

# Verificar labels
kubectl get nodes --show-labels
```

### Agregar Múltiples Workers

```bash
# Repetir el proceso en cada worker node:
# worker-node-2, worker-node-3, etc.

# Verificar todos los nodos
kubectl get nodes

# Output con 3 workers:
# NAME               STATUS   ROLES           AGE   VERSION
# control-plane      Ready    control-plane   20m   v1.28.0
# worker-node-1      Ready    worker          10m   v1.28.0
# worker-node-2      Ready    worker          5m    v1.28.0
# worker-node-3      Ready    worker          2m    v1.28.0
```

### Remover un Worker Node

```bash
# 1. Drenar el nodo (mover pods a otros nodos)
kubectl drain worker-node-1 --ignore-daemonsets --delete-emptydir-data

# 2. Eliminar el nodo del cluster
kubectl delete node worker-node-1

# 3. En el worker node, resetear kubeadm
sudo kubeadm reset

# 4. Limpiar reglas de iptables
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
```

---

## 7. High Availability (HA)

### Topologías HA

#### Opción 1: Stacked etcd (Más Simple)

```
┌─────────────────────────────────────────────┐
│         Load Balancer (HAProxy/NGINX)       │
│              VIP: 10.0.0.100:6443           │
└─────────────────┬───────────────────────────┘
                  │
      ┌───────────┴────────────┐
      │                        │
      ▼                        ▼
┌──────────────┐         ┌──────────────┐
│ Control 1    │         │ Control 2    │
│              │         │              │
│ ┌──────────┐ │         │ ┌──────────┐ │
│ │API Server│ │◄───────►│ │API Server│ │
│ └──────────┘ │         │ └──────────┘ │
│ ┌──────────┐ │         │ ┌──────────┐ │
│ │  etcd    │ │◄───────►│ │  etcd    │ │
│ └──────────┘ │         │ └──────────┘ │
└──────────────┘         └──────────────┘
```

**Ventajas**:
- ✅ Más simple de configurar
- ✅ Menos nodos requeridos
- ✅ Menos overhead

**Desventajas**:
- ⚠️ etcd acoplado al control plane
- ⚠️ Fallo de control plane afecta etcd

#### Opción 2: External etcd (Más Robusto)

```
┌─────────────────────────────────────────────┐
│         Load Balancer (HAProxy/NGINX)       │
│              VIP: 10.0.0.100:6443           │
└─────────────────┬───────────────────────────┘
                  │
      ┌───────────┴────────────┐
      │                        │
      ▼                        ▼
┌──────────────┐         ┌──────────────┐
│ Control 1    │         │ Control 2    │
│              │         │              │
│ ┌──────────┐ │         │ ┌──────────┐ │
│ │API Server│ │         │ │API Server│ │
│ └────┬─────┘ │         │ └────┬─────┘ │
└──────┼───────┘         └──────┼───────┘
       │                        │
       └────────────┬───────────┘
                    │
            ┌───────┴────────┐
            │                │
            ▼                ▼
      ┌─────────┐      ┌─────────┐
      │ etcd-1  │◄────►│ etcd-2  │
      └─────────┘      └─────────┘
            ▲                │
            └────────────────┘
```

**Ventajas**:
- ✅ etcd independiente
- ✅ Mayor resiliencia
- ✅ Escalabilidad separada

**Desventajas**:
- ⚠️ Más complejo
- ⚠️ Más nodos requeridos (6+ total)
- ⚠️ Mayor overhead operacional

### Configurar Load Balancer

#### HAProxy Configuration

```bash
# /etc/haproxy/haproxy.cfg
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

#### NGINX Configuration

```bash
# /etc/nginx/nginx.conf
stream {
    upstream kubernetes {
        server 10.0.0.10:6443 max_fails=3 fail_timeout=30s;
        server 10.0.0.11:6443 max_fails=3 fail_timeout=30s;
        server 10.0.0.12:6443 max_fails=3 fail_timeout=30s;
    }

    server {
        listen 6443;
        proxy_pass kubernetes;
        proxy_timeout 10m;
        proxy_connect_timeout 1s;
    }
}
```

### Inicializar Primer Control Plane

```bash
# Crear archivo de configuración
cat <<EOF > kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.28.0
controlPlaneEndpoint: "loadbalancer.example.com:6443"  # VIP del LB
networking:
  podSubnet: "192.168.0.0/16"
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
EOF

# Inicializar con upload de certificados
sudo kubeadm init --config=kubeadm-config.yaml --upload-certs

# IMPORTANTE: Guardar el output que contiene:
# 1. Join command para control plane nodes
# 2. Join command para worker nodes
# 3. Certificate key (válido 2 horas)
```

### Agregar Más Control Plane Nodes

```bash
# El comando se mostró en la salida de kubeadm init:
sudo kubeadm join loadbalancer.example.com:6443 \
  --token abc123.xyz789 \
  --discovery-token-ca-cert-hash sha256:hash... \
  --control-plane \
  --certificate-key cert-key-123...

# Si expira el certificate-key (>2 horas), regenerar:
# En el primer control plane:
sudo kubeadm init phase upload-certs --upload-certs
```

### Verificar HA

```bash
# Ver todos los control plane nodes
kubectl get nodes -l node-role.kubernetes.io/control-plane

# Ver pods de control plane en todos los nodos
kubectl get pods -n kube-system -o wide | grep -E 'api|controller|scheduler|etcd'

# Verificar salud de etcd
kubectl exec -it -n kube-system etcd-control-plane-1 -- \
  etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list

# Test de failover: Apagar un control plane
# El cluster debe seguir funcionando
```

---

## 8. Gestión de etcd

### ¿Qué es etcd?

etcd es el **almacén de datos distribuido** de Kubernetes que guarda:
- ✅ Configuración del cluster
- ✅ Estado de todos los recursos
- ✅ Secrets
- ✅ ConfigMaps
- ✅ Todo el estado del cluster

### Arquitectura de etcd

```
┌─────────────────────────────────────────┐
│          Kubernetes API Server          │
└──────────────────┬──────────────────────┘
                   │ gRPC
                   ▼
┌─────────────────────────────────────────┐
│                 etcd                    │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│  │ Member 1│◄─│ Member 2│◄─│ Member 3│ │
│  │(Leader) │──│(Follower│──│(Follower│ │
│  └─────────┘  └─────────┘  └─────────┘ │
│        Raft Consensus Protocol          │
└─────────────────────────────────────────┘
```

### Verificar Salud de etcd

```bash
# Opción 1: Desde un pod de etcd
kubectl exec -it -n kube-system etcd-<control-plane-name> -- sh -c \
  "ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health"

# Opción 2: Desde el control plane node
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# Output esperado:
# https://127.0.0.1:2379 is healthy: successfully committed proposal: took = 2.345ms
```

### Backup de etcd

**¿Por qué hacer backup?**
- 🔴 Pérdida de etcd = pérdida TOTAL del cluster
- 🔴 No se puede recrear el estado del cluster
- ✅ Backup permite disaster recovery

```bash
# Script de backup
#!/bin/bash
BACKUP_DIR="/backup/etcd"
DATE=$(date +%Y%m%d_%H%M%S)

sudo ETCDCTL_API=3 etcdctl snapshot save \
  ${BACKUP_DIR}/etcd-snapshot-${DATE}.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verificar backup
sudo ETCDCTL_API=3 etcdctl snapshot status \
  ${BACKUP_DIR}/etcd-snapshot-${DATE}.db \
  --write-out=table

# Comprimir
tar -czf ${BACKUP_DIR}/etcd-snapshot-${DATE}.tar.gz \
  ${BACKUP_DIR}/etcd-snapshot-${DATE}.db

# Limpiar snapshots antiguos (mantener últimos 7 días)
find ${BACKUP_DIR} -name "etcd-snapshot-*.tar.gz" -mtime +7 -delete

echo "Backup completed: etcd-snapshot-${DATE}.tar.gz"
```

### Restore de etcd

```bash
# 1. Detener API Server (para evitar escrituras)
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/

# 2. Restore del snapshot
sudo ETCDCTL_API=3 etcdctl snapshot restore \
  /backup/etcd/etcd-snapshot-20231113_120000.db \
  --data-dir=/var/lib/etcd-restore \
  --initial-cluster=control-plane-1=https://10.0.0.10:2380 \
  --initial-cluster-token=etcd-cluster-1 \
  --initial-advertise-peer-urls=https://10.0.0.10:2380

# 3. Actualizar manifiesto de etcd para usar nuevo data-dir
sudo vi /etc/kubernetes/manifests/etcd.yaml
# Cambiar:
# - --data-dir=/var/lib/etcd
# Por:
# - --data-dir=/var/lib/etcd-restore

# 4. Mover de vuelta el API Server
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

# 5. Esperar a que los pods se reinicien
watch kubectl get pods -n kube-system

# 6. Verificar cluster
kubectl get nodes
kubectl get pods --all-namespaces
```

### Monitoring de etcd

```bash
# Ver métricas de etcd
kubectl exec -it -n kube-system etcd-<control-plane> -- sh -c \
  "ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint status --write-out=table"

# Ver miembros de etcd
kubectl exec -it -n kube-system etcd-<control-plane> -- sh -c \
  "ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list --write-out=table"

# Alarmas de etcd
kubectl exec -it -n kube-system etcd-<control-plane> -- sh -c \
  "ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  alarm list"
```

---

## 9. Troubleshooting

### Problemas Comunes

#### 1. kubeadm init falla

**Síntoma**: `kubeadm init` termina con error

**Causas comunes**:
```bash
# Swap habilitado
free -h  # Si Swap > 0
sudo swapoff -a

# Puertos en uso
sudo netstat -tulpn | grep -E '6443|2379|10250'

# Container runtime no corriendo
sudo systemctl status containerd

# Prerequisites no cumplidos
sudo kubeadm init phase preflight

# Restos de instalación previa
sudo kubeadm reset
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/etcd/
```

#### 2. Nodo en estado NotReady

**Síntoma**: `kubectl get nodes` muestra STATUS=NotReady

**Diagnóstico**:
```bash
# Ver eventos del nodo
kubectl describe node <node-name>

# Ver logs de kubelet
sudo journalctl -u kubelet -f

# Verificar CNI
kubectl get pods -n kube-system | grep -E 'calico|flannel|weave'

# Verificar container runtime
sudo systemctl status containerd
crictl ps
```

**Soluciones**:
```bash
# Reiniciar kubelet
sudo systemctl restart kubelet

# Reinstalar CNI
kubectl delete -f <cni-manifest.yaml>
kubectl apply -f <cni-manifest.yaml>

# Verificar firewall
sudo iptables -L -n | grep 6443
```

#### 3. Pods en CrashLoopBackOff

**Síntoma**: Pods del sistema no inician

```bash
# Ver logs del pod
kubectl logs -n kube-system <pod-name>
kubectl describe pod -n kube-system <pod-name>

# Ver eventos
kubectl get events -n kube-system --sort-by='.lastTimestamp'

# Para pods static (api-server, etc)
sudo cat /var/log/pods/<namespace>_<pod>_<uid>/<container>/*.log
```

#### 4. Certificados Expirados

**Síntoma**: API Server no responde, certificados expirados

```bash
# Verificar expiración de certificados
sudo kubeadm certs check-expiration

# Renovar certificados
sudo kubeadm certs renew all

# Reiniciar control plane
sudo systemctl restart kubelet
```

#### 5. etcd No Saludable

**Síntoma**: Cluster inestable, objetos no se crean

```bash
# Verificar salud
kubectl exec -it -n kube-system etcd-<node> -- sh -c \
  "ETCDCTL_API=3 etcdctl endpoint health ..."

# Ver alarmas
kubectl exec -it -n kube-system etcd-<node> -- sh -c \
  "ETCDCTL_API=3 etcdctl alarm list ..."

# Si hay alarma de espacio:
kubectl exec -it -n kube-system etcd-<node> -- sh -c \
  "ETCDCTL_API=3 etcdctl defrag ..."
kubectl exec -it -n kube-system etcd-<node> -- sh -c \
  "ETCDCTL_API=3 etcdctl alarm disarm ..."
```

### Comandos de Diagnóstico

```bash
# Salud general del cluster
kubectl get componentstatuses  # Deprecated pero útil
kubectl get --raw='/readyz?verbose'
kubectl get --raw='/livez?verbose'

# Ver todos los recursos del sistema
kubectl get all -n kube-system

# Logs de kubelet
sudo journalctl -u kubelet -n 100 --no-pager

# Logs de containerd
sudo journalctl -u containerd -n 100 --no-pager

# Configuración de kubelet
sudo cat /var/lib/kubelet/config.yaml

# Verificar CNI config
ls -la /etc/cni/net.d/
cat /etc/cni/net.d/*.conf

# Ver rutas y reglas de red
ip route
sudo iptables -t nat -L -n -v
```

---

## 10. Mejores Prácticas

### Producción

1. **Alta Disponibilidad**
   - ✅ Mínimo 3 control plane nodes (número impar)
   - ✅ Load balancer redundante
   - ✅ etcd en nodos separados (opcional)
   - ✅ Múltiples worker nodes

2. **Backup & Disaster Recovery**
   - ✅ Backup automatizado de etcd (diario)
   - ✅ Almacenar backups off-site
   - ✅ Probar restore periódicamente
   - ✅ Documentar procedimientos

3. **Seguridad**
   - ✅ Deshabilitar acceso a kubelet API
   - ✅ Usar RBAC estricto
   - ✅ Rotar certificados regularmente
   - ✅ Network policies habilitadas
   - ✅ Pod Security Policies/Standards

4. **Monitoring & Logging**
   - ✅ Prometheus para métricas
   - ✅ Grafana para visualización
   - ✅ ELK/Loki para logs
   - ✅ Alertas configuradas

5. **Actualizaciones**
   - ✅ Mantener 2-3 versiones detrás de latest
   - ✅ Probar upgrades en staging primero
   - ✅ Seguir proceso de upgrade de kubeadm
   - ✅ Planificar ventanas de mantenimiento

### Sizing de Cluster

**Pequeño** (Dev/Test):
- 1 control plane
- 2-3 workers
- 4 vCPU, 8 GB RAM por nodo

**Mediano** (Staging/QA):
- 3 control planes
- 5-10 workers
- 8 vCPU, 16 GB RAM por nodo

**Grande** (Producción):
- 3+ control planes
- 20+ workers
- 16+ vCPU, 32+ GB RAM por nodo
- SSD storage
- 10 Gbps network

### Planificación de Capacidad

```
Pods por Nodo:
- Default: 110 pods/node
- Recomendado: 30-50 pods/node para mejor performance

CPU Overcommit:
- Desarrollo: 3:1
- Producción: 1.5:1 o 2:1

Memoria Overcommit:
- Desarrollo: 2:1
- Producción: 1:1 (sin overcommit)

Storage:
- etcd: IOPS altos, SSD recomendado
- Logs: 10-50 GB por nodo
- Images: 50-100 GB por nodo
```

---

## 📝 Resumen

En este módulo aprendiste:

✅ **Instalar Kubernetes** con kubeadm desde cero  
✅ **Configurar control plane** y worker nodes  
✅ **Implementar HA** con múltiples control planes  
✅ **Gestionar etcd** incluyendo backup/restore  
✅ **Configurar networking** con CNI plugins  
✅ **Troubleshootear** problemas comunes  
✅ **Aplicar mejores prácticas** de producción

### Comandos Esenciales

```bash
# Inicializar cluster
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# Agregar worker
sudo kubeadm join <endpoint>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

# Backup etcd
sudo ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db ...

# Verificar salud
kubectl get nodes
kubectl get pods -A
kubectl get componentstatuses
```

---

## 🔗 Referencias

- [kubeadm Documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [CNI Plugins](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)
- [etcd Documentation](https://etcd.io/docs/)
- [Cluster Administration](https://kubernetes.io/docs/tasks/administer-cluster/)

---

## ⏭️ Próximos Pasos

- **Laboratorios**: Practicar instalación hands-on
- **Módulo 23**: Maintenance & Upgrades
- **Módulo 26**: Troubleshooting avanzado

---

**¡Felicitaciones!** 🎉 Ahora sabes cómo instalar y gestionar clusters Kubernetes production-ready con kubeadm.
