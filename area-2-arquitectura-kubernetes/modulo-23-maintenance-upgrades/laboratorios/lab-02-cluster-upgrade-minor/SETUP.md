# Setup - Lab 02: Cluster Upgrade

Este documento describe los prerequisitos y pasos de configuración necesarios antes de comenzar el laboratorio de upgrade de cluster.

---

## 📋 Tabla de Contenidos

1. [Requisitos del Sistema](#requisitos-del-sistema)
2. [Prerequisitos de Software](#prerequisitos-de-software)
3. [Verificación de Prerequisitos](#verificación-de-prerequisitos)
4. [Configuración del Entorno](#configuración-del-entorno)
5. [Pre-lab Validation](#pre-lab-validation)
6. [Troubleshooting de Setup](#troubleshooting-de-setup)

---

## 🖥️ Requisitos del Sistema

### Arquitectura del Cluster

Este laboratorio requiere un cluster multi-nodo:

```
┌─────────────────────────────────────────┐
│          CONTROL PLANE NODE             │
│  - Ubuntu 20.04/22.04                   │
│  - 2 CPU, 4GB RAM, 20GB disco          │
│  - Kubernetes v1.27.x                   │
│  - kubeadm, kubelet, kubectl           │
└─────────────────────────────────────────┘
              │
              │ Network: 192.168.1.0/24
              │
    ┌─────────┴─────────┐
    │                   │
┌───▼────┐         ┌────▼───┐
│Worker-1│         │Worker-2│
│        │         │        │
│2CPU/4GB│         │2CPU/4GB│
│v1.27.x │         │v1.27.x │
└────────┘         └────────┘
```

### Hardware Mínimo

| Componente | Control Plane | Worker Nodes |
|------------|---------------|--------------|
| **CPU** | 2 cores | 2 cores |
| **RAM** | 4 GB | 4 GB |
| **Disco** | 20 GB | 20 GB |
| **Red** | 1 Gbps | 1 Gbps |

### Software Base

- **OS**: Ubuntu 20.04 LTS o 22.04 LTS (recomendado)
- **Container Runtime**: containerd v1.6+ o CRI-O v1.27+
- **Kubernetes**: v1.27.0-1.27.9 (pre-upgrade)
- **Target Version**: v1.28.0+

---

## 📦 Prerequisitos de Software

### 1. Cluster Kubernetes Funcional

Debes tener un cluster ya instalado con:

- ✅ kubeadm v1.27.x
- ✅ kubelet v1.27.x
- ✅ kubectl v1.27.x
- ✅ Container runtime configurado
- ✅ CNI plugin instalado (Calico, Flannel, etc.)

### 2. Acceso al Cluster

- ✅ SSH a todos los nodos (control plane + workers)
- ✅ Usuario con permisos sudo en todos los nodos
- ✅ kubeconfig configurado (`~/.kube/config`)

### 3. Herramientas Necesarias

En **todos los nodos**:
```bash
# Verificar que están instalados
which kubeadm kubelet kubectl
which apt-get  # Para Debian/Ubuntu
which systemctl
```

En el **nodo de administración** (puede ser control plane):
```bash
# Herramientas de verificación
which etcdctl  # Para backups
which jq       # Para parsing JSON (opcional)
```

### 4. Repositorios de Kubernetes

Asegúrate de tener el repositorio de Kubernetes configurado:

**Ubuntu/Debian:**
```bash
# Verificar repositorio
cat /etc/apt/sources.list.d/kubernetes.list

# Debe contener:
# deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /
```

---

## ✅ Verificación de Prerequisitos

### Paso 1: Verificar Cluster Actual

```bash
# 1. Verificar conectividad al cluster
kubectl cluster-info

# Output esperado:
# Kubernetes control plane is running at https://192.168.1.10:6443
# CoreDNS is running at https://192.168.1.10:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

```bash
# 2. Verificar todos los nodos están Ready
kubectl get nodes

# Output esperado:
# NAME                STATUS   ROLES           AGE   VERSION
# k8s-control-plane   Ready    control-plane   30d   v1.27.0
# k8s-worker-01       Ready    <none>          30d   v1.27.0
# k8s-worker-02       Ready    <none>          30d   v1.27.0
```

✅ **PASS**: Todos los nodos muestran STATUS=Ready  
❌ **FAIL**: Algún nodo en NotReady → Ver [Troubleshooting](#troubleshooting-de-setup)

```bash
# 3. Verificar versión actual
kubectl version --short

# Output esperado:
# Client Version: v1.27.0
# Server Version: v1.27.0
```

---

### Paso 2: Verificar Salud del Sistema

```bash
# 1. Pods del sistema funcionando
kubectl get pods -n kube-system

# Todos deben estar en Running o Completed
# CRITICAL PODS:
# - kube-apiserver-*         Running
# - kube-controller-manager-* Running
# - kube-scheduler-*         Running
# - etcd-*                   Running
# - coredns-*                Running
# - kube-proxy-*             Running
```

```bash
# 2. Verificar no hay pods en estado incorrecto
kubectl get pods -A | grep -vE 'Running|Completed|Succeeded'

# Output esperado: NINGUNO
# Si hay pods crasheando, investigar antes de proceder
```

```bash
# 3. Verificar events del cluster
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# Buscar eventos NORMALES, no errores críticos
```

✅ **PASS**: No eventos de error, todos los pods Running  
❌ **FAIL**: Pods crasheando → Resolver antes de upgrade

---

### Paso 3: Verificar Recursos del Sistema

```bash
# En cada nodo (control plane + workers)
ssh user@node

# 1. Verificar espacio en disco
df -h /var/lib

# Requiere al menos:
# - /var/lib/etcd: 5GB libres
# - /var/lib/kubelet: 10GB libres
# - /var/lib/containerd: 15GB libres
```

✅ **PASS**: Espacio suficiente  
⚠️ **WARNING**: <5GB libre → Limpiar antes de upgrade

```bash
# 2. Verificar memoria disponible
free -h

# Requiere al menos:
# Control Plane: 1GB libre
# Workers: 500MB libre
```

```bash
# 3. Verificar que no hay procesos problemáticos
top -bn1 | head -20

# Buscar procesos consumiendo >80% CPU/RAM
```

---

### Paso 4: Verificar Acceso SSH

```bash
# Desde tu máquina de administración
# Verificar acceso sin password (usando SSH keys)

ssh user@control-plane-node "hostname && whoami"
ssh user@worker-01-node "hostname && whoami"
ssh user@worker-02-node "hostname && whoami"

# Output esperado:
# k8s-control-plane
# user
# k8s-worker-01
# user
# ...
```

✅ **PASS**: Conexión exitosa sin password  
❌ **FAIL**: Requiere password → Configurar SSH keys:

```bash
# Generar keys si no existen
ssh-keygen -t rsa -b 4096

# Copiar a cada nodo
ssh-copy-id user@control-plane-node
ssh-copy-id user@worker-01-node
ssh-copy-id user@worker-02-node
```

---

### Paso 5: Verificar Permisos Sudo

```bash
# En cada nodo
ssh user@node "sudo -n true && echo 'SUDO OK' || echo 'SUDO FAIL'"

# Output esperado: SUDO OK
```

Si requiere password, configurar sudo sin password:

```bash
# En cada nodo como root
sudo visudo

# Agregar al final:
user ALL=(ALL) NOPASSWD: ALL

# O para grupo:
%admin ALL=(ALL) NOPASSWD: ALL
```

---

### Paso 6: Verificar Repositorio v1.28

```bash
# En control plane
sudo apt-get update

# Verificar que v1.28 está disponible
apt-cache madison kubeadm | grep 1.28

# Output esperado:
#    kubeadm | 1.28.0-00 | https://pkgs.k8s.io/core:/stable:/v1.28/deb  Packages
#    kubeadm | 1.28.1-00 | https://pkgs.k8s.io/core:/stable:/v1.28/deb  Packages
#    ...
```

✅ **PASS**: Versión 1.28.x visible  
❌ **FAIL**: No aparece → Ver [Configuración de Repositorio](#configurar-repositorio-kubernetes)

---

## 🔧 Configuración del Entorno

### Paso 1: Crear Directorios de Trabajo

```bash
# En control plane node
sudo mkdir -p /var/lib/etcd-backup
sudo mkdir -p /var/log/k8s-upgrade
sudo mkdir -p /root/k8s-manifests-backup

# Permisos
sudo chmod 750 /var/lib/etcd-backup
sudo chmod 755 /var/log/k8s-upgrade
```

---

### Paso 2: Configurar Variables de Entorno

```bash
# Crear archivo de configuración
cat > ~/upgrade-config.env << 'EOF'
# Kubernetes Upgrade Configuration
export CURRENT_VERSION="1.27.0"
export TARGET_VERSION="1.28.0"
export ETCD_BACKUP_DIR="/var/lib/etcd-backup"
export LOG_DIR="/var/log/k8s-upgrade"
export MANIFEST_BACKUP_DIR="/root/k8s-manifests-backup"

# Control Plane
export CONTROL_PLANE_NODE="k8s-control-plane"

# Worker Nodes (ajusta según tu cluster)
export WORKER_NODES="k8s-worker-01 k8s-worker-02"

# etcd Configuration
export ETCDCTL_API=3
export ETCD_CACERT="/etc/kubernetes/pki/etcd/ca.crt"
export ETCD_CERT="/etc/kubernetes/pki/etcd/server.crt"
export ETCD_KEY="/etc/kubernetes/pki/etcd/server.key"
export ETCD_ENDPOINTS="https://127.0.0.1:2379"
EOF

# Cargar variables
source ~/upgrade-config.env

# Agregar a .bashrc para persistencia
echo "source ~/upgrade-config.env" >> ~/.bashrc
```

---

### Paso 3: Instalar etcdctl (si no está)

```bash
# Verificar si existe
etcdctl version

# Si no existe, instalar:
ETCD_VERSION="v3.5.10"
wget https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz
tar xzvf etcd-${ETCD_VERSION}-linux-amd64.tar.gz
sudo mv etcd-${ETCD_VERSION}-linux-amd64/etcdctl /usr/local/bin/
sudo chmod +x /usr/local/bin/etcdctl
rm -rf etcd-${ETCD_VERSION}-linux-amd64*

# Verificar
etcdctl version
```

---

### Paso 4: Configurar Repositorio Kubernetes

**Para Ubuntu/Debian:**

```bash
# 1. Agregar repositorio v1.28
sudo mkdir -p /etc/apt/keyrings

# 2. Descargar GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-1-28-apt-keyring.gpg

# 3. Agregar repositorio
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-1-28-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | \
  sudo tee /etc/apt/sources.list.d/kubernetes-1.28.list

# 4. Actualizar índice
sudo apt-get update

# 5. Verificar
apt-cache madison kubeadm | grep 1.28
```

**REPETIR en todos los nodos** (control plane + workers)

---

### Paso 5: Crear Backup de etcd (CRÍTICO)

```bash
# Desde control plane node
sudo ETCDCTL_API=3 etcdctl snapshot save \
  ${ETCD_BACKUP_DIR}/snapshot-pre-upgrade-$(date +%Y%m%d-%H%M%S).db \
  --cacert=${ETCD_CACERT} \
  --cert=${ETCD_CERT} \
  --key=${ETCD_KEY} \
  --endpoints=${ETCD_ENDPOINTS}

# Verificar backup
sudo etcdctl snapshot status ${ETCD_BACKUP_DIR}/snapshot-pre-upgrade-*.db \
  --write-out=table
```

**Output esperado:**
```
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| 12ab34cd |    12345 |       1234 |     5.2 MB |
+----------+----------+------------+------------+
```

✅ **CRÍTICO**: Este backup es tu salvavidas si algo falla

---

### Paso 6: Backup de Manifests

```bash
# Backup de manifests estáticos
sudo cp -r /etc/kubernetes/manifests/* ${MANIFEST_BACKUP_DIR}/

# Backup de kubeadm-config
kubectl get cm kubeadm-config -n kube-system -o yaml > ${MANIFEST_BACKUP_DIR}/kubeadm-config.yaml

# Backup de kube-proxy config
kubectl get cm kube-proxy -n kube-system -o yaml > ${MANIFEST_BACKUP_DIR}/kube-proxy-config.yaml

# Listar backups
ls -lh ${MANIFEST_BACKUP_DIR}/
```

---

## 🧪 Pre-lab Validation

### Test 1: Conectividad del Cluster

```bash
# Script de validación
cat > ~/validate-cluster.sh << 'EOF'
#!/bin/bash
echo "=== Cluster Validation ==="

# Test 1: API Server
echo -n "API Server: "
kubectl cluster-info > /dev/null 2>&1 && echo "✅ OK" || echo "❌ FAIL"

# Test 2: All nodes Ready
echo -n "Nodes Ready: "
NOT_READY=$(kubectl get nodes | grep -c NotReady)
[ $NOT_READY -eq 0 ] && echo "✅ OK" || echo "❌ FAIL ($NOT_READY not ready)"

# Test 3: System pods
echo -n "System Pods: "
FAILING=$(kubectl get pods -n kube-system | grep -vE 'Running|Completed' | tail -n +2 | wc -l)
[ $FAILING -eq 0 ] && echo "✅ OK" || echo "❌ FAIL ($FAILING failing)"

# Test 4: etcd health
echo -n "etcd Health: "
sudo ETCDCTL_API=3 etcdctl endpoint health \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --endpoints=https://127.0.0.1:2379 > /dev/null 2>&1 && echo "✅ OK" || echo "❌ FAIL"

# Test 5: DNS resolution
echo -n "DNS Resolution: "
kubectl run test-dns --image=busybox:1.28 --rm -it --restart=Never -- nslookup kubernetes.default > /dev/null 2>&1 && echo "✅ OK" || echo "❌ FAIL"

echo "=== Validation Complete ==="
EOF

chmod +x ~/validate-cluster.sh
~/validate-cluster.sh
```

**Output esperado:**
```
=== Cluster Validation ===
API Server: ✅ OK
Nodes Ready: ✅ OK
System Pods: ✅ OK
etcd Health: ✅ OK
DNS Resolution: ✅ OK
=== Validation Complete ===
```

✅ **PASS**: Todos los tests OK  
❌ **FAIL**: Cualquier test falla → Resolver antes de continuar

---

### Test 2: Disponibilidad de Versión

```bash
# Verificar que la versión target está disponible
cat > ~/validate-version.sh << 'EOF'
#!/bin/bash
TARGET="1.28.0-00"
echo "Checking availability of Kubernetes $TARGET..."

for package in kubeadm kubelet kubectl; do
  echo -n "$package: "
  apt-cache madison $package | grep -q $TARGET && echo "✅ Available" || echo "❌ Not found"
done
EOF

chmod +x ~/validate-version.sh
~/validate-version.sh
```

---

### Test 3: Backup Verification

```bash
# Verificar que el backup de etcd es válido
cat > ~/validate-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/lib/etcd-backup"
LATEST=$(ls -t $BACKUP_DIR/snapshot-pre-upgrade-*.db 2>/dev/null | head -1)

if [ -z "$LATEST" ]; then
  echo "❌ No backup found"
  exit 1
fi

echo "Latest backup: $LATEST"
echo -n "Integrity check: "

sudo etcdctl snapshot status $LATEST --write-out=table > /dev/null 2>&1 && \
  echo "✅ OK" || echo "❌ CORRUPTED"

sudo ls -lh $LATEST
EOF

chmod +x ~/validate-backup.sh
~/validate-backup.sh
```

---

## 🔧 Troubleshooting de Setup

### Problema 1: Nodo en NotReady

**Síntomas:**
```
kubectl get nodes
NAME       STATUS     ROLES    AGE   VERSION
worker-01  NotReady   <none>   5d    v1.27.0
```

**Diagnóstico:**
```bash
# En el nodo afectado
sudo systemctl status kubelet
sudo journalctl -xeu kubelet | tail -50

# Verificar container runtime
sudo systemctl status containerd
```

**Soluciones comunes:**
```bash
# 1. Restart kubelet
sudo systemctl restart kubelet

# 2. Restart containerd
sudo systemctl restart containerd
sudo systemctl restart kubelet

# 3. Verificar CNI
ls /etc/cni/net.d/
kubectl get pods -n kube-system | grep -E 'calico|flannel'
```

---

### Problema 2: Repository Not Found

**Síntomas:**
```
E: The repository 'https://pkgs.k8s.io/... Release' does not have a Release file.
```

**Solución:**
```bash
# Eliminar repositorios viejos
sudo rm /etc/apt/sources.list.d/kubernetes*.list

# Reconfigurar desde cero
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-1-28-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-1-28-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
```

---

### Problema 3: etcd Backup Fails

**Síntomas:**
```
Error: context deadline exceeded
```

**Solución:**
```bash
# Verificar que etcd está corriendo
sudo crictl ps | grep etcd

# Verificar certificados
sudo ls -l /etc/kubernetes/pki/etcd/

# Probar conexión manual
sudo ETCDCTL_API=3 etcdctl endpoint health \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --endpoints=https://127.0.0.1:2379

# Reintentar backup con timeout mayor
sudo ETCDCTL_API=3 etcdctl snapshot save /tmp/test.db \
  --command-timeout=30s \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --endpoints=https://127.0.0.1:2379
```

---

### Problema 4: Disk Space Insufficient

**Síntomas:**
```
df -h
/var/lib    95%  Used
```

**Solución:**
```bash
# Limpiar imágenes no usadas
sudo crictl rmi --prune

# Limpiar containers stopped
sudo crictl rm $(sudo crictl ps -a -q --state=exited)

# Limpiar logs viejos
sudo journalctl --vacuum-time=7d

# Limpiar apt cache
sudo apt-get clean

# Verificar espacio ganado
df -h /var/lib
```

---

## ✅ Checklist Final Pre-Lab

Antes de comenzar el laboratorio, confirma:

- [ ] ✅ Cluster en v1.27.x funcionando correctamente
- [ ] ✅ Todos los nodos en estado Ready
- [ ] ✅ Pods del sistema en Running
- [ ] ✅ Backup de etcd creado y verificado
- [ ] ✅ Backup de manifests creado
- [ ] ✅ Repositorio v1.28 configurado en todos los nodos
- [ ] ✅ Acceso SSH sin password a todos los nodos
- [ ] ✅ Permisos sudo configurados
- [ ] ✅ Espacio en disco suficiente (>10GB libre en /var/lib)
- [ ] ✅ Variables de entorno configuradas
- [ ] ✅ etcdctl instalado
- [ ] ✅ Scripts de validación ejecutados exitosamente

**🎯 Si todos los items están ✅, estás listo para comenzar el laboratorio.**

---

## 📚 Referencias

- [kubeadm upgrade documentation](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
- [etcd backup best practices](https://etcd.io/docs/v3.5/op-guide/recovery/)
- [Version skew policy](https://kubernetes.io/releases/version-skew-policy/)

---

*Setup Guide - Lab 02: Cluster Upgrade | v1.0 | 2025-11-13*
