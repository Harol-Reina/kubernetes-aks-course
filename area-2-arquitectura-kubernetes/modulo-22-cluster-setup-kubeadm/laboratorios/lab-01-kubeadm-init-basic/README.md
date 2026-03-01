# Lab 01: Cluster Basico con kubeadm init

**Duracion estimada:** 2-3 horas
**Nivel:** Avanzado
**Objetivo:** Inicializar un cluster de Kubernetes single-master con kubeadm en VMs reales

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **kubeadm init** | Herramienta de bootstrap para inicializar el control plane de Kubernetes en una VM real |
| **InitConfiguration** | Configura el endpoint local del API Server (advertiseAddress, bindPort, criSocket) |
| **ClusterConfiguration** | Define parametros del cluster: version, networking (podSubnet, serviceSubnet), endpoints |
| **KubeletConfiguration** | Configura el kubelet local: cgroupDriver debe coincidir con containerd |
| **Calico CNI** | Plugin de red instalado post-init; requiere podSubnet 192.168.0.0/16 |
| **kubeadm preflight** | Validaciones automaticas previas al init: swap, puertos, container runtime |
| **Static Pods** | El control plane (apiserver, scheduler, controller-manager, etcd) corre como static pods |

---

## Archivos del Laboratorio

Este laboratorio usa un enfoque **declarativo con archivos de configuracion**. Las configuraciones se copian y editan en lugar de generarse con heredoc:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `kubeadm-config.yaml` | 1 | Configuracion kubeadm para inicializar cluster single master (editar IPs antes de usar) |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `validate-prerequisites.sh` | Script de validacion de prerequisites del sistema antes del init |
| `verify-cluster.sh` | Script de verificacion del cluster post-init |
| `cleanup.sh` | Script de limpieza completa del cluster (kubeadm reset + iptables) |

---

## Informacion del Laboratorio

- **Nombre**: Cluster Basico con kubeadm init
- **Modulo**: 22 - Cluster Setup with kubeadm
- **Area**: 2 - Arquitectura Kubernetes
- **Duracion**: 2-3 horas
- **Dificultad**: Avanzado
- **CKA relevance**: Alta (25% del examen - Cluster Architecture, Installation & Configuration)

## Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

1. **Instalar y configurar** todos los prerequisitos para un cluster de Kubernetes
2. **Inicializar** un cluster con `kubeadm init` usando configuración personalizada
3. **Configurar** networking del cluster con CNI plugin (Calico)
4. **Verificar** la salud del cluster y componentes del control plane
5. **Configurar** kubectl para administración del cluster
6. **Entender** la arquitectura de un cluster single-node básico

## 📐 Arquitectura del Cluster

```
┌─────────────────────────────────────────────────────────────┐
│                    CONTROL PLANE NODE                        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Control Plane Components                  │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐            │  │
│  │  │   etcd   │  │ API      │  │ Scheduler│            │  │
│  │  │  :2379   │  │ Server   │  │          │            │  │
│  │  │          │  │ :6443    │  │          │            │  │
│  │  └──────────┘  └──────────┘  └──────────┘            │  │
│  │                                                        │  │
│  │  ┌──────────┐  ┌──────────┐                          │  │
│  │  │ Controller│  │ Cloud    │                          │  │
│  │  │ Manager  │  │ Controller│                          │  │
│  │  │          │  │ (optional)│                          │  │
│  │  └──────────┘  └──────────┘                          │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                Node Components                         │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐            │  │
│  │  │ kubelet  │  │ kube-    │  │Container │            │  │
│  │  │          │  │ proxy    │  │ Runtime  │            │  │
│  │  │          │  │          │  │(containerd)│           │  │
│  │  └──────────┘  └──────────┘  └──────────┘            │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                  CNI Network Plugin                    │  │
│  │                   Calico (v3.26+)                      │  │
│  │              Pod CIDR: 192.168.0.0/16                  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 🔑 Conceptos Clave

### kubeadm init Workflow

```
1. Pre-flight checks
   ├── System validation
   ├── Port availability (6443, 2379-2380, 10250-10252)
   ├── Container runtime (containerd)
   └── Required tools (kubectl, kubelet)

2. Certificate generation
   ├── CA certificates
   ├── API server certificates
   ├── etcd certificates
   └── Service account key pair

3. Control plane static pods
   ├── kube-apiserver
   ├── kube-controller-manager
   ├── kube-scheduler
   └── etcd

4. kubeconfig generation
   ├── admin.conf
   ├── kubelet.conf
   ├── controller-manager.conf
   └── scheduler.conf

5. Bootstrap tokens
   └── For worker node join

6. Addons (optional)
   ├── CoreDNS
   └── kube-proxy
```

### Componentes Instalados

| Componente | Versión | Descripción | Puerto |
|------------|---------|-------------|--------|
| **kubelet** | 1.28+ | Node agent | 10250 |
| **kubeadm** | 1.28+ | Cluster bootstrap tool | - |
| **kubectl** | 1.28+ | CLI tool | - |
| **containerd** | 1.7+ | Container runtime | - |
| **etcd** | 3.5+ | Key-value store | 2379-2380 |
| **API Server** | 1.28+ | REST API frontend | 6443 |
| **Calico** | 3.26+ | CNI network plugin | - |

### Directorios Críticos

```bash
/etc/kubernetes/
├── manifests/              # Static pod manifests
│   ├── kube-apiserver.yaml
│   ├── kube-controller-manager.yaml
│   ├── kube-scheduler.yaml
│   └── etcd.yaml
├── admin.conf              # Admin kubeconfig
├── kubelet.conf            # Kubelet kubeconfig
├── controller-manager.conf # Controller manager kubeconfig
├── scheduler.conf          # Scheduler kubeconfig
└── pki/                    # Certificates
    ├── ca.crt
    ├── ca.key
    ├── apiserver.crt
    ├── apiserver.key
    ├── apiserver-kubelet-client.crt
    ├── apiserver-kubelet-client.key
    ├── front-proxy-ca.crt
    ├── front-proxy-ca.key
    ├── front-proxy-client.crt
    ├── front-proxy-client.key
    ├── sa.key
    ├── sa.pub
    └── etcd/
        ├── ca.crt
        ├── ca.key
        ├── server.crt
        └── server.key

/var/lib/kubelet/           # Kubelet data
/var/lib/etcd/              # etcd data
```

## 📋 Prerequisitos

Ver [SETUP.md](./SETUP.md) para:
- Sistema operativo soportado (Ubuntu 20.04/22.04, RHEL 8/9)
- Recursos mínimos (2 CPU, 2GB RAM, 20GB disk)
- Acceso root/sudo
- Network requirements (puertos, firewall)
- Container runtime instalado

## 🔬 Procedimiento del Laboratorio

### Parte 1: Preparación del Sistema (30 min)

#### 1.1 Deshabilitar swap

```bash
# Deshabilitar swap temporalmente
sudo swapoff -a

# Deshabilitar swap permanentemente
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Verificar
free -h
# Debe mostrar swap: 0B total
```

**¿Por qué?** Kubernetes requiere swap deshabilitado para garantizar rendimiento predecible de pods.

#### 1.2 Configurar módulos kernel y sysctl

```bash
# Cargar módulos necesarios
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configurar parámetros sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Aplicar configuración
sudo sysctl --system

# Verificar
lsmod | grep br_netfilter
lsmod | grep overlay
sysctl net.bridge.bridge-nf-call-iptables net.ipv4.ip_forward
```

#### 1.3 Instalar containerd

```bash
# Instalar dependencias
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Agregar Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Agregar repositorio
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list

# Instalar containerd
sudo apt-get update
sudo apt-get install -y containerd.io

# Generar configuración por defecto
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Configurar systemd cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' \
  /etc/containerd/config.toml

# Reiniciar containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# Verificar
sudo systemctl status containerd
```

#### 1.4 Instalar kubeadm, kubelet, kubectl

```bash
# Agregar Kubernetes GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Agregar repositorio Kubernetes
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

# Instalar paquetes
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# Bloquear versiones
sudo apt-mark hold kubelet kubeadm kubectl

# Verificar versiones
kubeadm version
kubelet --version
kubectl version --client
```

### Parte 2: Inicialización del Cluster (20 min)

#### 2.1 Preparar configuracion kubeadm

```bash
# Copiar archivo de configuracion kubeadm incluido en este lab
cp kubeadm-config.yaml ~/kubeadm-config.yaml

# IMPORTANTE: Sustituir los placeholders con valores reales del nodo

# Reemplazar <NODE_IP> con la IP principal del nodo:
NODE_IP=$(hostname -I | awk '{print $1}')
sed -i "s/<NODE_IP>/$NODE_IP/g" ~/kubeadm-config.yaml

# Reemplazar <NODE_HOSTNAME> con el hostname real:
sed -i "s/<NODE_HOSTNAME>/$(hostname)/g" ~/kubeadm-config.yaml

# Revisar configuracion resultante
cat ~/kubeadm-config.yaml
```

**Parámetros Clave:**
- `advertiseAddress`: IP del control plane (IP principal del nodo)
- `podSubnet`: CIDR para pods (192.168.0.0/16 para Calico)
- `serviceSubnet`: CIDR para services
- `cgroupDriver`: systemd (debe coincidir con containerd)

#### 2.2 Ejecutar kubeadm init

```bash
# Ejecutar pre-flight checks primero
sudo kubeadm init phase preflight --config ~/kubeadm-config.yaml

# Inicializar cluster
sudo kubeadm init --config ~/kubeadm-config.yaml --upload-certs

# OUTPUT ESPERADO:
# [init] Using Kubernetes version: v1.28.0
# [preflight] Running pre-flight checks
# [certs] Generating "ca" certificate and key
# [certs] Generating "apiserver" certificate and key
# ...
# [kubelet-start] Starting the kubelet
# [control-plane] Using manifest folder "/etc/kubernetes/manifests"
# [control-plane] Creating static Pod manifest for "kube-apiserver"
# [control-plane] Creating static Pod manifest for "kube-controller-manager"
# [control-plane] Creating static Pod manifest for "kube-scheduler"
# [etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
# [wait-control-plane] Waiting for the kubelet to boot up the control plane
# [apiclient] All control plane components are healthy
# [upload-config] Storing the configuration used in ConfigMap "kubeadm-config"
# [mark-control-plane] Marking the node as control-plane
# [bootstrap-token] Configuring bootstrap tokens
# 
# Your Kubernetes control-plane has initialized successfully!
```

**⚠️ IMPORTANTE**: Guarda el output, especialmente:
1. **kubeadm join command** (para agregar workers)
2. **Certificate key** (para agregar control planes en HA)

#### 2.3 Configurar kubectl para usuario regular

```bash
# Crear directorio .kube
mkdir -p $HOME/.kube

# Copiar admin.conf
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

# Cambiar ownership
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verificar
kubectl cluster-info

# OUTPUT:
# Kubernetes control plane is running at https://192.168.1.100:6443
# CoreDNS is running at https://192.168.1.100:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

### Parte 3: Instalar CNI Network Plugin (15 min)

#### 3.1 Instalar Calico

```bash
# Descargar Calico manifest
curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml \
  -O

# Aplicar Calico
kubectl apply -f calico.yaml

# Verificar despliegue de Calico
kubectl get pods -n kube-system -l k8s-app=calico-node -w

# Esperar hasta que todos los pods estén Running
# CTRL+C para salir del watch

# Verificar calico-kube-controllers
kubectl get deployment -n kube-system calico-kube-controllers
```

#### 3.2 Verificar networking

```bash
# Verificar que el nodo esté Ready
kubectl get nodes

# NAME            STATUS   ROLES           AGE   VERSION
# control-plane   Ready    control-plane   5m    v1.28.0

# Verificar que todos los pods system estén Running
kubectl get pods -n kube-system

# Verificar componentes del control plane
kubectl get pods -n kube-system -o wide | grep -E 'kube-apiserver|kube-scheduler|kube-controller|etcd'
```

### Parte 4: Verificación del Cluster (30 min)

#### 4.1 Verificar componentes del control plane

```bash
# Verificar API server
kubectl get --raw /healthz
# ok

kubectl get --raw /readyz
# ok

# Verificar etcd
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# 127.0.0.1:2379 is healthy: successfully committed proposal

# Verificar componentes como services
kubectl get componentstatuses
# (deprecated en 1.19+, usar endpoints)

kubectl get endpoints -n kube-system
```

#### 4.2 Verificar certificados

```bash
# Listar certificados
sudo kubeadm certs check-expiration

# CERTIFICATE                EXPIRES                  RESIDUAL TIME   ...
# admin.conf                 Nov 14, 2026 00:00 UTC   364d           ...
# apiserver                  Nov 14, 2026 00:00 UTC   364d           ...
# apiserver-kubelet-client   Nov 14, 2026 00:00 UTC   364d           ...
# ...

# Verificar CA certificate
openssl x509 -in /etc/kubernetes/pki/ca.crt -text -noout | grep -A 2 Validity

# Verificar API server certificate
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | \
  grep -E 'Subject:|DNS:|IP Address:'
```

#### 4.3 Verificar logs de componentes

```bash
# Logs de kubelet
sudo journalctl -u kubelet -n 50 --no-pager

# Logs de API server
kubectl logs -n kube-system kube-apiserver-$(hostname) | tail -20

# Logs de scheduler
kubectl logs -n kube-system kube-scheduler-$(hostname) | tail -20

# Logs de controller-manager
kubectl logs -n kube-system kube-controller-manager-$(hostname) | tail -20

# Logs de etcd
kubectl logs -n kube-system etcd-$(hostname) | tail -20
```

#### 4.4 Probar funcionalidad básica

```bash
# Crear namespace de prueba
kubectl create namespace test-cluster

# Crear deployment de prueba
kubectl create deployment nginx --image=nginx:latest -n test-cluster

# Verificar pod
kubectl get pods -n test-cluster -w

# Exponer deployment
kubectl expose deployment nginx --port=80 --type=NodePort -n test-cluster

# Obtener NodePort
kubectl get svc -n test-cluster

# Probar conectividad
NODE_PORT=$(kubectl get svc nginx -n test-cluster -o jsonpath='{.spec.ports[0].nodePort}')
curl http://localhost:$NODE_PORT

# Escalar deployment
kubectl scale deployment nginx --replicas=3 -n test-cluster

# Verificar pods distribuidos
kubectl get pods -n test-cluster -o wide

# Verificar logs
kubectl logs -n test-cluster deployment/nginx --tail=10

# Limpiar
kubectl delete namespace test-cluster
```

### Parte 5: Configuración Post-Instalación (20 min)

#### 5.1 Habilitar autocompletion de kubectl

```bash
# Para bash
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc

# Para zsh
echo 'source <(kubectl completion zsh)' >>~/.zshrc
echo 'alias k=kubectl' >>~/.zshrc

# Aplicar cambios
source ~/.bashrc  # o source ~/.zshrc
```

#### 5.2 Configurar bash prompt con contexto

```bash
# Instalar kube-ps1
git clone https://github.com/jonmosco/kube-ps1.git ~/.kube-ps1

# Agregar a .bashrc
cat <<'EOF' >> ~/.bashrc
source ~/.kube-ps1/kube-ps1.sh
PS1='[\u@\h \W $(kube_ps1)]\$ '
EOF

# Aplicar
source ~/.bashrc
```

#### 5.3 Instalar herramientas útiles

```bash
# kubectx/kubens (cambiar contextos/namespaces)
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# k9s (TUI para Kubernetes)
wget https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz
tar -xzf k9s_Linux_amd64.tar.gz
sudo mv k9s /usr/local/bin/
rm k9s_Linux_amd64.tar.gz

# Verificar instalación
kubectx
kubens
k9s version
```

#### 5.4 Backup de certificados y kubeconfig

```bash
# Crear directorio de backups
mkdir -p ~/k8s-backups/$(date +%Y%m%d)

# Backup de PKI
sudo tar -czf ~/k8s-backups/$(date +%Y%m%d)/pki-backup.tar.gz \
  /etc/kubernetes/pki

# Backup de kubeconfig
sudo cp /etc/kubernetes/admin.conf \
  ~/k8s-backups/$(date +%Y%m%d)/admin.conf.backup

# Backup de manifests
sudo tar -czf ~/k8s-backups/$(date +%Y%m%d)/manifests-backup.tar.gz \
  /etc/kubernetes/manifests

# Verificar backups
ls -lh ~/k8s-backups/$(date +%Y%m%d)/
```

## 🔍 Troubleshooting

### Problema 1: kubeadm init falla en preflight checks

**Síntoma:**
```
[ERROR Port-6443]: Port 6443 is in use
[ERROR Port-10259]: Port 10259 is in use
```

**Solución:**
```bash
# Verificar qué proceso usa el puerto
sudo netstat -tulpn | grep 6443

# Si hay un cluster anterior, hacer reset
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes
sudo rm -rf /var/lib/kubelet
sudo rm -rf /var/lib/etcd

# Reiniciar servicios
sudo systemctl restart containerd
sudo systemctl restart kubelet

# Reintentar kubeadm init
```

### Problema 2: Nodo permanece NotReady

**Síntoma:**
```bash
kubectl get nodes
# NAME     STATUS      ROLES           AGE   VERSION
# node1    NotReady    control-plane   5m    v1.28.0
```

**Solución:**
```bash
# Verificar CNI plugin instalado
kubectl get pods -n kube-system | grep calico

# Si no hay pods de Calico, reinstalar
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# Verificar logs de kubelet
sudo journalctl -u kubelet -f

# Verificar logs de containerd
sudo journalctl -u containerd -f

# Reiniciar kubelet si es necesario
sudo systemctl restart kubelet
```

### Problema 3: Pods en CrashLoopBackOff

**Síntoma:**
```bash
kubectl get pods -n kube-system
# NAME                        READY   STATUS             RESTARTS
# kube-apiserver-node1        0/1     CrashLoopBackOff   5
```

**Solución:**
```bash
# Ver logs del pod
kubectl logs -n kube-system kube-apiserver-$(hostname) --previous

# Verificar manifest del static pod
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml

# Verificar permisos de certificados
sudo ls -la /etc/kubernetes/pki/

# Regenerar certificados si es necesario
sudo kubeadm init phase certs apiserver --config ~/kubeadm-config.yaml

# Esperar que kubelet reinicie el pod
kubectl get pods -n kube-system -w
```

### Problema 4: CoreDNS en Pending

**Síntoma:**
```bash
kubectl get pods -n kube-system
# NAME                      READY   STATUS    RESTARTS   AGE
# coredns-787d4945fb-xxx    0/1     Pending   0          5m
```

**Solución:**
```bash
# Verificar CNI plugin
kubectl get pods -n kube-system -l k8s-app=calico-node

# Ver detalles del pod CoreDNS
kubectl describe pod -n kube-system -l k8s-app=kube-dns

# Verificar eventos
kubectl get events -n kube-system --sort-by='.lastTimestamp'

# Si el nodo tiene taint control-plane, CoreDNS no podrá schedulear
# Remover taint si es cluster single-node
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

### Problema 5: Error de conexión a API server

**Síntoma:**
```bash
kubectl get nodes
# The connection to the server 192.168.1.100:6443 was refused
```

**Solución:**
```bash
# Verificar que API server esté corriendo
sudo crictl ps | grep kube-apiserver

# Verificar puerto 6443
sudo netstat -tulpn | grep 6443

# Verificar manifest
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml

# Verificar logs de kubelet
sudo journalctl -u kubelet -n 100 --no-pager | grep apiserver

# Verificar conectividad
curl -k https://$(hostname -I | awk '{print $1}'):6443/healthz

# Si es problema de certificados, regenerar
sudo kubeadm init phase certs all --config ~/kubeadm-config.yaml
```

## 📚 Comandos Útiles para CKA

### Información del Cluster

```bash
# Versión del cluster
kubectl version

# Info del cluster
kubectl cluster-info
kubectl cluster-info dump

# Componentes del cluster
kubectl get componentstatuses  # deprecated
kubectl get --raw /healthz
kubectl get --raw /livez
kubectl get --raw /readyz

# Configuración de kubeadm
kubectl get cm -n kube-system kubeadm-config -o yaml
```

### Gestión de Nodos

```bash
# Listar nodos con detalles
kubectl get nodes -o wide

# Describir nodo
kubectl describe node <node-name>

# Ver labels del nodo
kubectl get nodes --show-labels

# Ver capacity y allocatable
kubectl get nodes -o custom-columns=\
NAME:.metadata.name,\
CPU-CAP:.status.capacity.cpu,\
CPU-ALLOC:.status.allocatable.cpu,\
MEM-CAP:.status.capacity.memory,\
MEM-ALLOC:.status.allocatable.memory
```

### Gestión de Pods

```bash
# Pods por nodo
kubectl get pods -A -o wide --field-selector spec.nodeName=<node-name>

# Pods en namespace kube-system
kubectl get pods -n kube-system -o wide

# Static pods (control plane)
kubectl get pods -n kube-system -o wide | grep $(hostname)

# Logs de pods del sistema
kubectl logs -n kube-system <pod-name>
```

### Certificados

```bash
# Verificar expiración
sudo kubeadm certs check-expiration

# Renovar todos los certificados
sudo kubeadm certs renew all

# Renovar certificado específico
sudo kubeadm certs renew apiserver

# Ver detalles del certificado
openssl x509 -in /etc/kubernetes/pki/ca.crt -text -noout
```

## 🎓 Preparación para el Examen CKA

### Escenario Típico del Examen

**Tarea**: "Inicializa un nuevo cluster de Kubernetes usando kubeadm. Configura el pod network CIDR como 10.244.0.0/16 y el service CIDR como 10.96.0.0/12. Instala Calico como CNI plugin."

**Solución en 5 minutos:**

```bash
# 1. Crear kubeadm config (1 min)
cat <<EOF > /tmp/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
networking:
  podSubnet: "10.244.0.0/16"
  serviceSubnet: "10.96.0.0/12"
EOF

# 2. Inicializar cluster (2 min)
sudo kubeadm init --config /tmp/kubeadm-config.yaml

# 3. Configurar kubectl (30 seg)
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 4. Instalar Calico (1 min)
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# 5. Verificar (30 seg)
kubectl get nodes
kubectl get pods -n kube-system
```

### Comandos Críticos para Memorizar

```bash
# kubeadm init básico
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# kubeadm con config file
sudo kubeadm init --config kubeadm-config.yaml

# Reset cluster
sudo kubeadm reset -f

# Verificar certificados
sudo kubeadm certs check-expiration

# Renovar certificados
sudo kubeadm certs renew all

# Ver configuración de kubeadm
kubectl get cm -n kube-system kubeadm-config -o yaml

# Configurar kubectl
export KUBECONFIG=/etc/kubernetes/admin.conf
```

### Tiempo Estimado en Examen

- **kubeadm init**: ~3-4 minutos
- **Configurar kubectl**: ~30 segundos
- **Instalar CNI**: ~1 minuto
- **Verificación**: ~1 minuto
- **Total**: ~6 minutos (de 120 minutos totales del examen)

## 🧹 Limpieza

Para limpiar completamente el laboratorio:

```bash
# Usar script de cleanup
./cleanup.sh

# O manual:
# 1. Eliminar namespace de prueba
kubectl delete namespace test-cluster --ignore-not-found

# 2. Reset kubeadm
sudo kubeadm reset -f

# 3. Limpiar directorios
sudo rm -rf /etc/kubernetes
sudo rm -rf /var/lib/kubelet
sudo rm -rf /var/lib/etcd
sudo rm -rf $HOME/.kube

# 4. Limpiar iptables
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X

# 5. Reiniciar servicios
sudo systemctl restart containerd
sudo systemctl restart kubelet
```

## 📖 Referencias

- [kubeadm Official Documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [kubeadm Configuration API](https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/)
- [Installing Calico](https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart)
- [Container Runtime](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
- [PKI certificates and requirements](https://kubernetes.io/docs/setup/best-practices/certificates/)

## ✅ Verificación de Conocimientos

- [ ] Entiendes el flujo completo de `kubeadm init`
- [ ] Puedes configurar prerequisitos del sistema (swap, módulos, sysctl)
- [ ] Sabes instalar y configurar containerd
- [ ] Puedes crear un archivo de configuración de kubeadm personalizado
- [ ] Entiendes la estructura de directorios de `/etc/kubernetes`
- [ ] Sabes instalar y verificar un CNI plugin (Calico)
- [ ] Puedes troubleshoot problemas comunes de inicialización
- [ ] Sabes verificar la salud del cluster y componentes
- [ ] Entiendes la importancia de backup de certificados
- [ ] Puedes completar `kubeadm init` en menos de 5 minutos (CKA)

---

**Próximo Lab**: [Lab 02 - Worker Node Join](../lab-02-worker-node-join/README.md)
