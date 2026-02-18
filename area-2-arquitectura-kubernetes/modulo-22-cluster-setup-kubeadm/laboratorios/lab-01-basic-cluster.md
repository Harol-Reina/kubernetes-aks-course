# Lab 01: Setup de Cluster Kubernetes Básico con kubeadm

**Duración estimada:** 45-60 minutos  
**Dificultad:** ⭐⭐ Intermedio

## 🎯 Objetivos

Al completar este laboratorio, serás capaz de:
- ✅ Instalar y configurar prerequisites para Kubernetes
- ✅ Inicializar un control plane con kubeadm
- ✅ Configurar networking con Calico CNI
- ✅ Agregar worker nodes al cluster
- ✅ Verificar el estado del cluster

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────┐
│         k8s-master-01                    │
│       192.168.1.10                       │
│  ┌─────────────────────────────────┐   │
│  │ Control Plane Components:       │   │
│  │  - API Server (6443)            │   │
│  │  - Controller Manager           │   │
│  │  - Scheduler                    │   │
│  │  - etcd                         │   │
│  │  - kubelet + containerd         │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
                  |
        ┌─────────┴─────────┐
        |                   |
┌───────────────┐   ┌───────────────┐
│ k8s-worker-01 │   │ k8s-worker-02 │
│ 192.168.1.20  │   │ 192.168.1.21  │
│               │   │               │
│ - kubelet     │   │ - kubelet     │
│ - kube-proxy  │   │ - kube-proxy  │
│ - containerd  │   │ - containerd  │
└───────────────┘   └───────────────┘
```

## 📋 Prerequisites

### Hardware
- **Control Plane**: 2 CPU, 2GB RAM, 20GB disk
- **Workers**: 1 CPU, 1GB RAM, 20GB disk (mínimo)

### Software
- Ubuntu 20.04+ o 22.04 LTS (recomendado)
- Acceso root (sudo)
- Conectividad de red entre nodos

### Preparación
```bash
# En TODOS los nodos: Configurar hostnames y /etc/hosts
sudo hostnamectl set-hostname k8s-master-01  # En master
sudo hostnamectl set-hostname k8s-worker-01  # En worker-01
sudo hostnamectl set-hostname k8s-worker-02  # En worker-02

# Agregar entradas en /etc/hosts (todos los nodos)
sudo tee -a /etc/hosts <<EOF
192.168.1.10 k8s-master-01
192.168.1.20 k8s-worker-01
192.168.1.21 k8s-worker-02
EOF

# Verificar conectividad
ping -c 3 k8s-master-01
ping -c 3 k8s-worker-01
ping -c 3 k8s-worker-02
```

---

## 🚀 Paso 1: Instalar Prerequisites (TODOS los nodos)

### 1.1 Usar Script de Instalación

```bash
# Descargar o copiar el script install-prerequisites.sh
# Ver: ../scripts/install-prerequisites.sh

# Hacer ejecutable
chmod +x install-prerequisites.sh

# Ejecutar con sudo
sudo ./install-prerequisites.sh
```

El script realizará:
- ✅ Deshabilitar swap
- ✅ Configurar módulos del kernel (overlay, br_netfilter)
- ✅ Configurar sysctl (ip_forward, bridge-nf-call)
- ✅ Instalar containerd
- ✅ Configurar systemd cgroup driver
- ✅ Instalar kubeadm, kubelet, kubectl

### 1.2 Verificar Instalación

```bash
# Verificar versiones instaladas
kubeadm version
kubelet --version
kubectl version --client

# Verificar containerd
sudo systemctl status containerd

# Verificar que swap está deshabilitado
free -h  # Swap debe mostrar 0

# Verificar módulos del kernel
lsmod | grep br_netfilter
lsmod | grep overlay
```

**✅ Checkpoint**: Todos los comandos deben ejecutarse sin errores.

---

## 🎮 Paso 2: Inicializar Control Plane (SOLO MASTER)

### 2.1 Ejecutar kubeadm init

```bash
# En k8s-master-01
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --apiserver-advertise-address=192.168.1.10 \
  --control-plane-endpoint=k8s-master-01:6443

# O usar configuración personalizada
sudo kubeadm init --config ../ejemplos/kubeadm-config.yaml
```

**⚠️ IMPORTANTE**: Guardar el output completo, especialmente:
```
kubeadm join k8s-master-01:6443 --token abcdef.0123456789abcdef \
  --discovery-token-ca-cert-hash sha256:1234567890abcdef...
```

### 2.2 Configurar kubeconfig

```bash
# Configurar acceso para usuario normal
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verificar acceso al cluster
kubectl cluster-info
kubectl get nodes
```

**Salida esperada:**
```
NAME            STATUS     ROLES           AGE   VERSION
k8s-master-01   NotReady   control-plane   30s   v1.28.0
```

**NotReady** es normal, falta instalar CNI plugin.

### 2.3 Verificar Componentes del Control Plane

```bash
# Ver pods del sistema
kubectl get pods -n kube-system

# Verificar componentes específicos
kubectl get pods -n kube-system -l component=kube-apiserver
kubectl get pods -n kube-system -l component=kube-controller-manager
kubectl get pods -n kube-system -l component=kube-scheduler
kubectl get pods -n kube-system -l component=etcd
```

**✅ Checkpoint**: Todos los pods deben estar Running.

---

## 🌐 Paso 3: Instalar CNI Plugin - Calico (SOLO MASTER)

### 3.1 Aplicar Manifesto de Calico

```bash
# Opción A: Calico por defecto
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Opción B: Calico personalizado
kubectl apply -f ../ejemplos/calico-custom.yaml
```

### 3.2 Verificar Instalación de Calico

```bash
# Ver pods de Calico iniciando
kubectl get pods -n kube-system -w

# Verificar DaemonSet
kubectl get daemonset -n kube-system calico-node

# Verificar deployment
kubectl get deployment -n kube-system calico-kube-controllers

# Esperar hasta que todos estén Running (2-3 minutos)
watch kubectl get pods -n kube-system
```

### 3.3 Verificar Nodo Ready

```bash
# El nodo debe pasar a Ready después de CNI
kubectl get nodes

# Salida esperada:
# NAME            STATUS   ROLES           AGE   VERSION
# k8s-master-01   Ready    control-plane   5m    v1.28.0
```

**✅ Checkpoint**: Nodo master en estado **Ready**.

---

## 👷 Paso 4: Agregar Worker Nodes

### 4.1 Obtener Join Command (En Master)

Si perdiste el join command original:

```bash
# Generar nuevo token
kubeadm token create --print-join-command

# Salida:
# kubeadm join k8s-master-01:6443 --token abc123.xyz456 \
#   --discovery-token-ca-cert-hash sha256:789abc...
```

### 4.2 Ejecutar Join en Workers

```bash
# En k8s-worker-01 y k8s-worker-02
sudo kubeadm join k8s-master-01:6443 \
  --token abc123.xyz456 \
  --discovery-token-ca-cert-hash sha256:789abc...
```

**Salida esperada:**
```
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[kubelet-start] Writing kubelet configuration to file
[kubelet-start] Starting the kubelet
This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.
```

### 4.3 Verificar Workers en el Cluster (En Master)

```bash
# Ver todos los nodos
kubectl get nodes

# Ver detalles de nodos
kubectl get nodes -o wide

# Ver labels de nodos
kubectl get nodes --show-labels
```

**Salida esperada:**
```
NAME            STATUS   ROLES           AGE     VERSION
k8s-master-01   Ready    control-plane   10m     v1.28.0
k8s-worker-01   Ready    <none>          2m      v1.28.0
k8s-worker-02   Ready    <none>          1m      v1.28.0
```

**✅ Checkpoint**: 3 nodos en estado **Ready**.

---

## 🧪 Paso 5: Verificación y Testing

### 5.1 Test de Conectividad de Red

```bash
# Crear deployment de prueba
kubectl create deployment nginx --image=nginx --replicas=3

# Verificar pods distribuidos en workers
kubectl get pods -o wide

# Exponer servicio
kubectl expose deployment nginx --port=80 --type=NodePort

# Obtener NodePort asignado
kubectl get svc nginx

# Probar acceso
curl http://k8s-worker-01:<NODE_PORT>
curl http://k8s-worker-02:<NODE_PORT>
```

### 5.2 Test de DNS

```bash
# Crear pod de prueba
kubectl run test-pod --image=busybox --restart=Never -- sleep 3600

# Probar DNS interno
kubectl exec test-pod -- nslookup kubernetes.default
kubectl exec test-pod -- nslookup nginx

# Probar DNS externo
kubectl exec test-pod -- nslookup google.com
```

### 5.3 Verificar Logs

```bash
# Logs del API server
kubectl logs -n kube-system -l component=kube-apiserver

# Logs de kubelet (en cualquier nodo)
sudo journalctl -u kubelet -f

# Logs de containerd
sudo journalctl -u containerd -f
```

### 5.4 Cluster Info

```bash
# Información del cluster
kubectl cluster-info

# Dump completo (para debugging)
kubectl cluster-info dump > cluster-dump.txt

# Versiones de componentes
kubectl version
kubectl get nodes -o yaml | grep kubelet
```

---

## 📊 Paso 6: Validaciones Finales

### Checklist de Validación

Ejecuta cada comando y verifica:

```bash
# ✅ 1. Todos los nodos Ready
kubectl get nodes
# Esperado: 3 nodos, STATUS=Ready

# ✅ 2. Todos los pods del sistema Running
kubectl get pods -n kube-system
# Esperado: No pods en Error o CrashLoopBackOff

# ✅ 3. Componentes del control plane saludables
kubectl get componentstatuses  # Deprecated en 1.28+
kubectl get --raw='/readyz?verbose'
# Esperado: [+]ping ok, [+]etcd ok, etc.

# ✅ 4. Endpoints del API server
kubectl get endpoints -n default kubernetes
# Esperado: IP del master en ENDPOINTS

# ✅ 5. DNS funcionando
kubectl run dns-test --image=busybox --restart=Never --rm -it -- nslookup kubernetes.default
# Esperado: Resolución exitosa

# ✅ 6. Calico funcionando
kubectl get pods -n kube-system -l k8s-app=calico-node
# Esperado: 3 pods (1 por nodo), STATUS=Running

# ✅ 7. Workloads pueden ejecutarse
kubectl run test-nginx --image=nginx --port=80
kubectl expose pod test-nginx --type=NodePort
kubectl get svc test-nginx
curl http://<NODE_IP>:<NODE_PORT>
# Esperado: Página de bienvenida de nginx

# Limpieza de test
kubectl delete pod test-nginx
kubectl delete svc test-nginx
```

---

## 🎓 Desafíos Opcionales

### Desafío 1: Etiquetar Workers
```bash
# Agregar labels a workers
kubectl label node k8s-worker-01 node-role.kubernetes.io/worker=worker
kubectl label node k8s-worker-02 node-role.kubernetes.io/worker=worker

# Verificar
kubectl get nodes
```

### Desafío 2: Configurar Autocompletion
```bash
# Bash completion para kubectl
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
source ~/.bashrc

# Probar
k get no<TAB>  # Autocompleta a 'nodes'
```

### Desafío 3: Instalar Metrics Server
```bash
# Instalar metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verificar
kubectl top nodes
kubectl top pods -A
```

---

## 🧹 Limpieza (Opcional)

Si necesitas destruir el cluster:

```bash
# En CADA worker
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo rm -rf $HOME/.kube

# En el master
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo rm -rf $HOME/.kube
sudo rm -rf /var/lib/etcd

# En TODOS los nodos (opcional, limpiar iptables)
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
```

---

## 🐛 Troubleshooting

### Problema: Nodo en NotReady

```bash
# Verificar kubelet
sudo systemctl status kubelet
sudo journalctl -u kubelet -f

# Común: CNI plugin no instalado
kubectl get pods -n kube-system | grep calico
```

### Problema: Pods en Pending

```bash
# Ver eventos
kubectl describe pod <pod-name>

# Común: Taint en master impide scheduling
kubectl describe node k8s-master-01 | grep Taint
```

### Problema: Error "swap is enabled"

```bash
# Deshabilitar swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

### Problema: Token expirado

```bash
# Generar nuevo token (en master)
kubeadm token create --print-join-command
```

---

## 📚 Recursos Adicionales

- [kubeadm init documentation](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/)
- [Calico Installation](https://docs.projectcalico.org/getting-started/kubernetes/)
- [Troubleshooting kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/)

---

## ✅ Criterios de Completitud

Has completado exitosamente este lab si:
- [ ] 3 nodos en estado Ready (1 master + 2 workers)
- [ ] Todos los pods kube-system en Running
- [ ] DNS resuelve correctamente
- [ ] Pods pueden ejecutarse en workers
- [ ] Networking funciona entre pods
- [ ] kubectl funciona sin sudo

**¡Felicitaciones!** 🎉 Tienes un cluster Kubernetes funcional.

**Próximo paso:** [Lab 02: Multi-Node Production Cluster](./lab-02-multi-node-cluster.md)
