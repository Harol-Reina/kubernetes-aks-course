# Setup - Lab 03: Node Drain & Cordon

Este documento describe los prerequisitos y configuración necesarios para el laboratorio de mantenimiento de nodos.

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

### Arquitectura Mínima del Cluster

Este laboratorio requiere **al menos 2 worker nodes** para demostrar la migración de pods:

```
┌─────────────────────────────────────┐
│       CONTROL PLANE NODE            │
│  - Ubuntu 20.04/22.04               │
│  - 2 CPU, 4GB RAM                   │
│  - Kubernetes v1.27+ o v1.28+       │
└─────────────────────────────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
┌───▼────┐         ┌────▼───┐
│Worker-1│         │Worker-2│
│        │         │        │
│2CPU/4GB│         │2CPU/4GB│
│Ready   │         │Ready   │
└────────┘         └────────┘
```

### Hardware Mínimo

| Componente | Control Plane | Worker Nodes (mínimo 2) |
|------------|---------------|-------------------------|
| **CPU** | 2 cores | 2 cores cada uno |
| **RAM** | 4 GB | 4 GB cada uno |
| **Disco** | 20 GB | 20 GB cada uno |
| **Red** | 1 Gbps | 1 Gbps |

### Software Base

- **OS**: Ubuntu 20.04 LTS o 22.04 LTS
- **Kubernetes**: v1.27.0+ o v1.28.0+
- **Container Runtime**: containerd v1.6+ o CRI-O
- **CNI**: Calico, Flannel, Weave, o similar

---

## 📦 Prerequisitos de Software

### 1. Cluster Kubernetes Funcional

Debes tener un cluster con:

- ✅ Al menos **2 worker nodes** en estado `Ready`
- ✅ kubectl configurado con acceso admin
- ✅ CNI plugin instalado y funcional
- ✅ CoreDNS operacional

### 2. Acceso y Permisos

- ✅ kubectl con permisos de cluster-admin
- ✅ Capacidad de crear/eliminar namespaces
- ✅ Capacidad de crear PodDisruptionBudgets

### 3. Recursos Disponibles

El cluster debe tener capacidad para:

- ✅ Correr 10-15 pods simultáneos
- ✅ Mover pods entre nodos (recursos suficientes)
- ✅ Crear deployments con múltiples réplicas

---

## ✅ Verificación de Prerequisitos

### Paso 1: Verificar Número de Nodos

```bash
# Listar todos los nodos
kubectl get nodes

# Output esperado (MÍNIMO):
# NAME                STATUS   ROLES           AGE   VERSION
# k8s-control-plane   Ready    control-plane   30d   v1.28.0
# k8s-worker-01       Ready    <none>          30d   v1.28.0
# k8s-worker-02       Ready    <none>          30d   v1.28.0
```

✅ **PASS**: Al menos 2 nodos worker en estado `Ready`  
❌ **FAIL**: Menos de 2 workers → **BLOQUEANTE** - No puedes continuar

**Si solo tienes 1 worker:**
```bash
# Opción 1: Agregar otro nodo worker (recomendado)
# Ver: Lab 02 de Módulo 22 (Worker Node Join)

# Opción 2: Usar minikube multi-node
minikube start --nodes 3

# Opción 3: Usar kind multi-node
kind create cluster --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
```

---

### Paso 2: Verificar Recursos de Nodos

```bash
# Ver capacidad de cada nodo
kubectl describe nodes | grep -A 5 "Capacity:"

# Verificar que hay recursos disponibles
kubectl top nodes

# Output esperado:
# NAME                CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# k8s-worker-01       200m         10%    1500Mi          37%
# k8s-worker-02       180m         9%     1400Mi          35%
```

✅ **PASS**: Cada worker tiene <70% CPU y <70% memoria usado  
⚠️ **WARNING**: >70% usado → Lab puede tener problemas durante evacuación

---

### Paso 3: Verificar Conectividad kubectl

```bash
# Test de conexión
kubectl cluster-info

# Output esperado:
# Kubernetes control plane is running at https://192.168.1.10:6443
# CoreDNS is running at ...
```

```bash
# Verificar permisos admin
kubectl auth can-i create pods
kubectl auth can-i delete nodes

# Ambos deben retornar: yes
```

✅ **PASS**: Conexión OK y permisos suficientes  
❌ **FAIL**: Sin permisos → Configurar RBAC o usar otro kubeconfig

---

### Paso 4: Verificar Pods del Sistema

```bash
# Verificar componentes core
kubectl get pods -n kube-system

# Componentes críticos que deben estar Running:
# - coredns-* (2 pods)
# - kube-proxy-* (1 por nodo)
# - CNI pods (calico-node-*, flannel-*, etc.)
```

✅ **PASS**: Todos los pods en `Running`  
❌ **FAIL**: Pods crasheando → Resolver antes de continuar

---

### Paso 5: Test de Scheduling

```bash
# Crear pod de prueba
kubectl run test-pod --image=nginx:alpine

# Verificar que se programa correctamente
kubectl get pod test-pod -o wide

# Eliminar
kubectl delete pod test-pod
```

✅ **PASS**: Pod se creó y está Running  
❌ **FAIL**: Pod en Pending → Verificar recursos/CNI

---

## 🔧 Configuración del Entorno

### Paso 1: Etiquetar Nodos (Opcional)

Para identificar fácilmente los workers:

```bash
# Etiquetar workers
kubectl label node k8s-worker-01 node-role.kubernetes.io/worker=worker
kubectl label node k8s-worker-02 node-role.kubernetes.io/worker=worker

# Verificar
kubectl get nodes

# Output:
# NAME                STATUS   ROLES           AGE   VERSION
# k8s-control-plane   Ready    control-plane   30d   v1.28.0
# k8s-worker-01       Ready    worker          30d   v1.28.0
# k8s-worker-02       Ready    worker          30d   v1.28.0
```

---

### Paso 2: Crear Namespace de Prueba

```bash
# Crear namespace para el lab
kubectl create namespace drain-test

# Verificar
kubectl get namespace drain-test
```

---

### Paso 3: Configurar Aliases (Opcional)

```bash
# Agregar a ~/.bashrc o ~/.zshrc
cat >> ~/.bashrc << 'EOF'
# Kubernetes aliases para Lab 03
alias k='kubectl'
alias kgn='kubectl get nodes'
alias kgp='kubectl get pods -n drain-test -o wide'
alias kdrain='kubectl drain --ignore-daemonsets --delete-emptydir-data'
EOF

source ~/.bashrc
```

---

### Paso 4: Script Helper de Distribución de Pods

```bash
# Crear script para ver distribución de pods
cat > ~/pods-by-node.sh << 'EOF'
#!/bin/bash
echo "=== Pods por Nodo ==="
for node in $(kubectl get nodes -o name | cut -d'/' -f2); do
  echo ""
  echo "📍 $node:"
  kubectl get pods -A -o wide --field-selector spec.nodeName=$node | grep -v "NAMESPACE" | wc -l | xargs echo "  Total pods:"
  kubectl get pods -n drain-test -o wide --field-selector spec.nodeName=$node --no-headers | wc -l | xargs echo "  drain-test pods:"
done
EOF

chmod +x ~/pods-by-node.sh

# Uso:
# ~/pods-by-node.sh
```

---

## 🧪 Pre-lab Validation

### Test 1: Multi-Node Cluster Validation

```bash
# Script de validación
cat > ~/validate-lab03-setup.sh << 'EOF'
#!/bin/bash
echo "=== Lab 03 Setup Validation ==="
echo ""

# Test 1: Número de workers
WORKERS=$(kubectl get nodes --no-headers | grep -v control-plane | wc -l)
echo -n "Workers disponibles: "
if [ $WORKERS -ge 2 ]; then
  echo "✅ $WORKERS (OK)"
else
  echo "❌ $WORKERS (Se requieren mínimo 2)"
  exit 1
fi

# Test 2: Nodos Ready
NOT_READY=$(kubectl get nodes --no-headers | grep -c NotReady)
echo -n "Nodos NotReady: "
if [ $NOT_READY -eq 0 ]; then
  echo "✅ 0 (OK)"
else
  echo "❌ $NOT_READY (Resolver antes de continuar)"
  kubectl get nodes
  exit 1
fi

# Test 3: Permisos
echo -n "Permisos drain: "
if kubectl auth can-i delete pods > /dev/null 2>&1; then
  echo "✅ OK"
else
  echo "❌ Insuficientes"
  exit 1
fi

# Test 4: Namespace
echo -n "Namespace drain-test: "
if kubectl get namespace drain-test > /dev/null 2>&1; then
  echo "✅ Existe"
else
  echo "⚠️  No existe (se creará automáticamente)"
fi

# Test 5: Capacidad de recursos
echo -n "Recursos disponibles: "
TOTAL_PODS=$(kubectl get pods -A --no-headers | wc -l)
if [ $TOTAL_PODS -lt 50 ]; then
  echo "✅ Suficiente ($TOTAL_PODS/50 pods)"
else
  echo "⚠️  Cluster muy lleno ($TOTAL_PODS pods)"
fi

echo ""
echo "=== Validación Completada ==="
EOF

chmod +x ~/validate-lab03-setup.sh
~/validate-lab03-setup.sh
```

**Output esperado:**
```
=== Lab 03 Setup Validation ===

Workers disponibles: ✅ 2 (OK)
Nodos NotReady: ✅ 0 (OK)
Permisos drain: ✅ OK
Namespace drain-test: ✅ Existe
Recursos disponibles: ✅ Suficiente (12/50 pods)

=== Validación Completada ===
```

---

### Test 2: Scheduling Test

```bash
# Test de scheduling en múltiples nodos
cat > ~/test-scheduling.sh << 'EOF'
#!/bin/bash
echo "=== Test de Scheduling Multi-Nodo ==="

# Crear deployment temporal
kubectl create deployment test-sched --image=nginx:alpine --replicas=4 -n default

sleep 10

# Ver distribución
echo ""
echo "Distribución de pods:"
kubectl get pods -l app=test-sched -o wide

# Verificar que están en diferentes nodos
NODES=$(kubectl get pods -l app=test-sched -o jsonpath='{.items[*].spec.nodeName}' | tr ' ' '\n' | sort -u | wc -l)

echo ""
echo -n "Nodos usados: "
if [ $NODES -ge 2 ]; then
  echo "✅ $NODES (pods distribuidos)"
else
  echo "⚠️  $NODES (todos en mismo nodo - verificar scheduler)"
fi

# Cleanup
kubectl delete deployment test-sched -n default

echo ""
echo "=== Test Completado ==="
EOF

chmod +x ~/test-scheduling.sh
~/test-scheduling.sh
```

---

### Test 3: PodDisruptionBudget Support

```bash
# Verificar que PDBs están soportados
kubectl api-resources | grep PodDisruptionBudget

# Output esperado:
# poddisruptionbudgets   pdb   policy/v1   true   PodDisruptionBudget
```

✅ **PASS**: PDB aparece en api-resources  
❌ **FAIL**: No aparece → Versión de Kubernetes muy vieja (<1.21)

---

## 🔧 Troubleshooting de Setup

### Problema 1: Solo 1 Worker Node

**Síntomas:**
```bash
kubectl get nodes
# Solo aparece 1 worker
```

**Soluciones:**

**Opción A: Minikube multi-node** (recomendado para testing)
```bash
# Detener cluster actual
minikube stop

# Iniciar con múltiples nodos
minikube start --nodes 3 --cpus 2 --memory 4096

# Verificar
kubectl get nodes
```

**Opción B: kind multi-node**
```bash
kind create cluster --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
EOF
```

**Opción C: Agregar worker real**
```bash
# En el nuevo nodo worker, ejecutar kubeadm join
# (Obtener comando del control plane)
sudo kubeadm token create --print-join-command
```

---

### Problema 2: Nodos en NotReady

**Síntomas:**
```bash
kubectl get nodes
NAME          STATUS     ROLES    AGE   VERSION
worker-01     NotReady   <none>   5d    v1.28.0
```

**Diagnóstico:**
```bash
# Ver detalles del nodo
kubectl describe node worker-01

# Buscar en conditions:
# Type: Ready
# Status: False
# Reason: <motivo>
```

**Soluciones comunes:**

**CNI no instalado/funcionando:**
```bash
# Verificar pods de CNI
kubectl get pods -n kube-system | grep -E 'calico|flannel|weave'

# Reinstalar CNI si es necesario (ejemplo Calico)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

**kubelet no corriendo:**
```bash
# SSH al nodo
ssh worker-01

# Verificar kubelet
sudo systemctl status kubelet
sudo systemctl restart kubelet
```

---

### Problema 3: Recursos Insuficientes

**Síntomas:**
```bash
kubectl top nodes
NAME          CPU(cores)   MEMORY(bytes)
worker-01     1800m/2000m  3500Mi/4000Mi  # >90% usado
```

**Solución:**
```bash
# Eliminar pods no esenciales
kubectl delete deployment <non-essential-deployments>

# O agregar más recursos al nodo
# (VM: aumentar CPU/RAM)
# (Cloud: cambiar instance type)
```

---

### Problema 4: Sin Permisos para Drain

**Síntomas:**
```bash
kubectl drain worker-01
Error from server (Forbidden): error when evicting pod...
```

**Solución:**
```bash
# Verificar permisos actuales
kubectl auth can-i delete pods
kubectl auth can-i create pods/eviction

# Si eres admin, crear ClusterRoleBinding
kubectl create clusterrolebinding drain-admin \
  --clusterrole=cluster-admin \
  --user=$(whoami)

# O usar kubeconfig con permisos admin
export KUBECONFIG=/etc/kubernetes/admin.conf
```

---

### Problema 5: PDBs No Soportados

**Síntomas:**
```bash
kubectl api-resources | grep PodDisruptionBudget
# No retorna nada
```

**Causa**: Kubernetes < v1.21

**Solución:**
```bash
# Verificar versión
kubectl version --short

# Si < 1.21, upgradear cluster
# Ver Lab 02: Cluster Upgrade

# O saltarse la parte de PDBs en el lab
```

---

## ✅ Checklist Final Pre-Lab

Antes de comenzar el laboratorio, confirma:

- [ ] ✅ **Al menos 2 worker nodes** en estado Ready
- [ ] ✅ Todos los nodos con **recursos disponibles** (<70% CPU/RAM)
- [ ] ✅ kubectl con **permisos de admin** (can-i delete pods)
- [ ] ✅ **CNI funcional** (networking entre pods)
- [ ] ✅ **CoreDNS operacional** (DNS resolution)
- [ ] ✅ Namespace `drain-test` creado
- [ ] ✅ Scripts de validación ejecutados exitosamente
- [ ] ✅ **PodDisruptionBudgets soportados** (api-resources)
- [ ] ✅ Pods se pueden **programar en múltiples nodos**

**🎯 Si todos los items están ✅, estás listo para comenzar el laboratorio.**

---

## 📚 Referencias

- [Node Maintenance - Kubernetes Docs](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)
- [PodDisruptionBudgets](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
- [kubectl drain reference](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#drain)

---

*Setup Guide - Lab 03: Node Drain & Cordon | v1.0 | 2025-11-13*
