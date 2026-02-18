# Lab 02: Upgrade de Cluster Kubernetes (Minor Version)

**Duración estimada:** 45-60 minutos  
**Dificultad:** ⭐⭐⭐ Avanzado  
**Relevancia CKA:** 🔴 CRÍTICO (Cluster Maintenance 25%)

---

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

- ✅ Planificar y ejecutar un upgrade de cluster Kubernetes
- ✅ Actualizar control plane con `kubeadm upgrade`
- ✅ Actualizar worker nodes sin downtime de aplicaciones
- ✅ Verificar compatibilidad de versiones
- ✅ Realizar rollback en caso de problemas
- ✅ Entender el proceso de upgrade step-by-step

---

## 📋 Prerequisitos

Antes de comenzar, asegúrate de:

1. ✅ Tener un cluster Kubernetes funcional (v1.27.x)
2. ✅ Acceso SSH a todos los nodos (control plane + workers)
3. ✅ Permisos de root o sudo en todos los nodos
4. ✅ Backup reciente de etcd (ver Lab 01)
5. ✅ Al menos 2 worker nodes para testing sin downtime

**Verifica prerequisitos:**
```bash
# Verificar versión actual del cluster
kubectl version --short

# Verificar todos los nodos
kubectl get nodes -o wide

# Verificar pods críticos funcionando
kubectl get pods -n kube-system
```

📖 **Ver detalles completos**: [SETUP.md](./SETUP.md)

---

## 🏗️ Arquitectura del Upgrade

```
┌─────────────────────────────────────────────────────────────┐
│                    PROCESO DE UPGRADE                        │
└─────────────────────────────────────────────────────────────┘

FASE 1: PREPARACIÓN
┌──────────────┐
│   v1.27.0    │  ← Cluster actual
│ Control+Work │
└──────────────┘
       │
       │ 1. Backup etcd
       │ 2. Verificar compatibilidad
       │ 3. Drenar nodos
       ▼

FASE 2: UPGRADE CONTROL PLANE
┌──────────────┐     ┌──────────────┐
│   v1.27.0    │ →   │   v1.28.0    │
│  Workers     │     │ Control Plane│
└──────────────┘     └──────────────┘
       │
       │ kubeadm upgrade apply v1.28.0
       │ upgrade kubelet + kubectl
       │ restart kubelet
       ▼

FASE 3: UPGRADE WORKERS (uno por uno)
┌──────────────┐     ┌──────────────┐
│  Worker-1    │ →   │  Worker-1    │
│   v1.27.0    │     │   v1.28.0    │
└──────────────┘     └──────────────┘
       │
       │ drain → upgrade → uncordon
       │ (pods migran a worker-2)
       ▼
┌──────────────┐     ┌──────────────┐
│  Worker-2    │ →   │  Worker-2    │
│   v1.27.0    │     │   v1.28.0    │
└──────────────┘     └──────────────┘

RESULTADO FINAL:
┌──────────────────────────────────┐
│    CLUSTER v1.28.0 COMPLETO      │
│  Control Plane + All Workers     │
└──────────────────────────────────┘
```

---

## 📚 Conceptos Clave

### ¿Qué es un Upgrade de Cluster?

Un **upgrade de cluster** actualiza los componentes de Kubernetes a una versión más reciente:

**Componentes actualizados**:
- 🎛️ **Control Plane**: API Server, Controller Manager, Scheduler, etcd
- 🖥️ **Node components**: kubelet, kube-proxy
- 📦 **Add-ons**: CoreDNS, CNI plugins

### Skew Policy de Kubernetes

**Reglas de compatibilidad** (críticas para CKA):

```
kube-apiserver: v1.28.0 (base version)
   ↓
controller-manager: v1.28.0 o v1.27.x (hasta -1 minor)
   ↓
scheduler: v1.28.0 o v1.27.x (hasta -1 minor)
   ↓
kubelet: v1.28.0, v1.27.x, v1.26.x (hasta -2 minor)
   ↓
kubectl: v1.29.x, v1.28.0, v1.27.x (±1 minor)
```

⚠️ **IMPORTANTE**: Solo puedes upgradear **una minor version** a la vez:
- ✅ v1.27.0 → v1.28.0 (OK)
- ❌ v1.27.0 → v1.29.0 (NO permitido, debes ir v1.27→v1.28→v1.29)

### Estrategias de Upgrade

**1. Rolling Upgrade** (recomendado para producción):
- Actualizar control plane primero
- Actualizar workers uno por uno
- Zero downtime para aplicaciones
- Pods migran entre nodos

**2. In-place Upgrade** (testing/desarrollo):
- Detener cluster completo
- Actualizar todos los componentes
- Reiniciar cluster
- ⚠️ Causa downtime completo

**En este lab usaremos Rolling Upgrade** ✅

---

## 🛠️ Procedimiento del Laboratorio

### Parte 1: Preparación del Upgrade

#### Paso 1.1: Verificar versión actual

```bash
# Versión de componentes
kubectl version --short

# Versión de nodos
kubectl get nodes -o wide

# Versión de kubelet en cada nodo
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.kubeletVersion}{"\n"}{end}'
```

**✅ Output esperado:**
```
NAME               VERSION
k8s-control-plane  v1.27.0
k8s-worker-01      v1.27.0
k8s-worker-02      v1.27.0
```

#### Paso 1.2: Crear backup de etcd

```bash
# CRÍTICO: Backup antes de cualquier upgrade
sudo ETCDCTL_API=3 etcdctl snapshot save /var/lib/etcd-backup/snapshot-pre-upgrade-$(date +%Y%m%d).db \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --endpoints=https://127.0.0.1:2379

# Verificar backup
sudo etcdctl snapshot status /var/lib/etcd-backup/snapshot-pre-upgrade-*.db --write-out=table
```

#### Paso 1.3: Verificar salud del cluster

```bash
# Verificar que todos los nodos están Ready
kubectl get nodes

# Verificar pods del sistema
kubectl get pods -n kube-system

# Verificar que no hay pods en estado no deseado
kubectl get pods -A | grep -vE 'Running|Completed'
```

#### Paso 1.4: Revisar versiones disponibles

```bash
# En el nodo control plane
sudo apt update
sudo apt-cache madison kubeadm | head -10

# O para sistemas con yum
sudo yum list --showduplicates kubeadm
```

**✅ Buscar:** `1.28.0-00` o `1.28.x-00`

---

### Parte 2: Upgrade del Control Plane

#### Paso 2.1: Actualizar kubeadm en control plane

```bash
# SSH al nodo control plane
ssh user@control-plane-node

# Actualizar kubeadm a v1.28.0
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.0-00
sudo apt-mark hold kubeadm

# Verificar versión
kubeadm version
```

**✅ Output esperado:**
```
kubeadm version: &version.Info{Major:"1", Minor:"28", GitVersion:"v1.28.0", ...}
```

#### Paso 2.2: Planificar el upgrade (dry-run)

```bash
# Ver qué cambios se aplicarán
sudo kubeadm upgrade plan
```

**✅ Output esperado (extracto):**
```
Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   CURRENT       TARGET
kubelet     3 x v1.27.0   v1.28.0

Upgrade to the latest stable version:

COMPONENT                 CURRENT   TARGET
kube-apiserver            v1.27.0   v1.28.0
kube-controller-manager   v1.27.0   v1.28.0
kube-scheduler            v1.27.0   v1.28.0
kube-proxy                v1.27.0   v1.28.0
CoreDNS                   v1.10.1   v1.11.1
etcd                      3.5.9-0   3.5.9-0

You can now apply the upgrade by executing the following command:

	kubeadm upgrade apply v1.28.0
```

#### Paso 2.3: Aplicar upgrade al control plane

```bash
# IMPORTANTE: Este paso actualiza los componentes del control plane
sudo kubeadm upgrade apply v1.28.0
```

**Proceso esperado** (toma 3-5 minutos):
```
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[preflight] Running pre-flight checks.
[upgrade] Running cluster health checks
[upgrade/version] You have chosen to change the cluster version to "v1.28.0"
[upgrade/versions] Cluster version: v1.27.0
[upgrade/versions] kubeadm version: v1.28.0
[upgrade/confirm] Are you sure you want to proceed with the upgrade? [y/N]: y
...
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.28.0". Enjoy!
```

✅ **Escribe `y` cuando se te pregunte**

#### Paso 2.4: Drenar el nodo control plane

```bash
# Desde un nodo con kubectl configurado
kubectl drain k8s-control-plane --ignore-daemonsets --delete-emptydir-data
```

**Output esperado:**
```
node/k8s-control-plane cordoned
WARNING: ignoring DaemonSet-managed Pods: kube-system/kube-proxy-xxxxx
evicting pod kube-system/coredns-xxxxx
pod/coredns-xxxxx evicted
node/k8s-control-plane drained
```

#### Paso 2.5: Actualizar kubelet y kubectl en control plane

```bash
# En el nodo control plane
sudo apt-mark unhold kubelet kubectl
sudo apt-get update
sudo apt-get install -y kubelet=1.28.0-00 kubectl=1.28.0-00
sudo apt-mark hold kubelet kubectl

# Reiniciar kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Verificar status
sudo systemctl status kubelet
```

#### Paso 2.6: Uncordon el control plane

```bash
# Permitir scheduling de nuevo
kubectl uncordon k8s-control-plane

# Verificar que el nodo está Ready
kubectl get nodes
```

**✅ Output esperado:**
```
NAME                STATUS   ROLES           AGE   VERSION
k8s-control-plane   Ready    control-plane   30d   v1.28.0  ← Actualizado!
k8s-worker-01       Ready    <none>          30d   v1.27.0
k8s-worker-02       Ready    <none>          30d   v1.27.0
```

---

### Parte 3: Upgrade de Worker Nodes

#### Paso 3.1: Upgrade Worker Node 1

**A. Drenar el nodo**

```bash
# Desde el control plane o un nodo con kubectl
kubectl drain k8s-worker-01 --ignore-daemonsets --delete-emptydir-data

# Verificar que los pods migraron
kubectl get pods -o wide | grep -v worker-01
```

**B. SSH al worker node**

```bash
ssh user@k8s-worker-01
```

**C. Actualizar kubeadm**

```bash
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.0-00
sudo apt-mark hold kubeadm
```

**D. Upgrade node configuration**

```bash
# Actualizar configuración del nodo
sudo kubeadm upgrade node
```

**✅ Output esperado:**
```
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[preflight] Running pre-flight checks
[preflight] Skipping prepull. Not a control plane node.
[upgrade] Skipping phase. Not a control plane node.
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[upgrade] The configuration for this node was successfully updated!
[upgrade] Now you should go ahead and upgrade the kubelet package using your package manager.
```

**E. Actualizar kubelet y kubectl**

```bash
sudo apt-mark unhold kubelet kubectl
sudo apt-get update
sudo apt-get install -y kubelet=1.28.0-00 kubectl=1.28.0-00
sudo apt-mark hold kubelet kubectl

# Reiniciar kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo systemctl status kubelet
```

**F. Uncordon el nodo**

```bash
# Desde control plane
kubectl uncordon k8s-worker-01

# Verificar
kubectl get nodes
```

**✅ Verificación:**
```
NAME                STATUS   ROLES           AGE   VERSION
k8s-control-plane   Ready    control-plane   30d   v1.28.0
k8s-worker-01       Ready    <none>          30d   v1.28.0  ← Actualizado!
k8s-worker-02       Ready    <none>          30d   v1.27.0
```

#### Paso 3.2: Upgrade Worker Node 2

**Repetir el mismo proceso que Worker 1:**

```bash
# 1. Drenar
kubectl drain k8s-worker-02 --ignore-daemonsets --delete-emptydir-data

# 2. SSH al nodo
ssh user@k8s-worker-02

# 3. Actualizar kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.0-00
sudo apt-mark hold kubeadm

# 4. Upgrade node
sudo kubeadm upgrade node

# 5. Actualizar kubelet + kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get install -y kubelet=1.28.0-00 kubectl=1.28.0-00
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# 6. Uncordon (desde control plane)
kubectl uncordon k8s-worker-02
```

---

### Parte 4: Verificación Post-Upgrade

#### Paso 4.1: Verificar versiones de todos los nodos

```bash
kubectl get nodes -o wide
```

**✅ ÉXITO - Todos en v1.28.0:**
```
NAME                STATUS   ROLES           AGE   VERSION
k8s-control-plane   Ready    control-plane   30d   v1.28.0
k8s-worker-01       Ready    <none>          30d   v1.28.0
k8s-worker-02       Ready    <none>          30d   v1.28.0
```

#### Paso 4.2: Verificar componentes del control plane

```bash
# Verificar pods del sistema
kubectl get pods -n kube-system

# Verificar versión de API server
kubectl version --short

# Verificar events del cluster
kubectl get events -A | head -20
```

#### Paso 4.3: Probar funcionalidad del cluster

```bash
# Crear deployment de prueba
kubectl create deployment nginx-test --image=nginx:alpine --replicas=3

# Verificar que se crean correctamente
kubectl get pods -l app=nginx-test -o wide

# Escalar
kubectl scale deployment nginx-test --replicas=5

# Verificar distribución entre nodos
kubectl get pods -o wide | grep nginx-test

# Limpiar
kubectl delete deployment nginx-test
```

#### Paso 4.4: Verificar add-ons actualizados

```bash
# CoreDNS
kubectl get deployment coredns -n kube-system -o wide

# Kube-proxy
kubectl get ds kube-proxy -n kube-system -o wide

# CNI (si aplica)
kubectl get pods -n kube-system | grep -E 'calico|flannel|weave'
```

---

## 🧪 Validación del Laboratorio

### Checklist de Completitud

- [ ] **Backup de etcd** creado pre-upgrade
- [ ] **Control plane** actualizado a v1.28.0
- [ ] **Todos los workers** actualizados a v1.28.0
- [ ] **Pods del sistema** en estado Running
- [ ] **Aplicaciones de prueba** funcionan correctamente
- [ ] **Sin eventos** de error en el cluster
- [ ] **CoreDNS** operacional (resolución DNS funciona)
- [ ] **Networking** funcional entre pods
- [ ] **Rollback plan** documentado (en caso necesario)
- [ ] **Cleanup** ejecutado

### Script de Verificación Automatizado

```bash
./verify-upgrade.sh
```

El script verificará:
- ✅ Versiones de todos los nodos
- ✅ Salud de componentes del sistema
- ✅ Funcionalidad de networking
- ✅ DNS resolution
- ✅ Pod scheduling

---

## 🔍 Troubleshooting

### Problema 1: kubeadm upgrade plan falla

**Síntomas:**
```
couldn't create a Kubernetes client from file "/etc/kubernetes/admin.conf"
```

**Solución:**
```bash
# Verificar que tienes permisos
sudo -i

# Verificar que el archivo existe
ls -l /etc/kubernetes/admin.conf

# Regenerar si es necesario
sudo kubeadm init phase kubeconfig admin
```

---

### Problema 2: kubelet no inicia después del upgrade

**Síntomas:**
```
sudo systemctl status kubelet
● kubelet.service - kubelet: The Kubernetes Node Agent
   Loaded: loaded
   Active: activating (auto-restart)
```

**Diagnóstico:**
```bash
# Ver logs
sudo journalctl -xeu kubelet | tail -50

# Verificar configuración
sudo cat /var/lib/kubelet/config.yaml
```

**Soluciones comunes:**
```bash
# 1. Verificar que containerd está corriendo
sudo systemctl status containerd
sudo systemctl restart containerd

# 2. Reiniciar kubelet después de restart de runtime
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# 3. Verificar permisos
sudo chown root:root /var/lib/kubelet/config.yaml
```

---

### Problema 3: Pods no migran durante drain

**Síntomas:**
```
error when evicting pods/"xxx" -n "default" (will retry after 5s):
Cannot evict pod as it would violate the pod's disruption budget.
```

**Solución:**
```bash
# Ver PodDisruptionBudgets
kubectl get pdb -A

# Opción 1: Esperar a que termine periodo de disruption
# Opción 2: Forzar drain (CUIDADO en producción)
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data --force --grace-period=0

# Opción 3: Temporalmente eliminar PDB
kubectl delete pdb <pdb-name> -n <namespace>
# (Recuerda recrearlo después)
```

---

### Problema 4: Versión de kubeadm no disponible

**Síntomas:**
```
E: Version '1.28.0-00' for 'kubeadm' was not found
```

**Solución:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-cache madison kubeadm

# Si no aparece la versión:
# 1. Verificar repositorio
cat /etc/apt/sources.list.d/kubernetes.list

# 2. Actualizar repositorio si es necesario
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
```

---

### Problema 5: Control plane no acepta conexiones después de upgrade

**Síntomas:**
```bash
kubectl get nodes
The connection to the server <ip>:6443 was refused
```

**Diagnóstico:**
```bash
# En control plane node
sudo crictl ps | grep kube-apiserver
sudo crictl logs <apiserver-container-id>

# Verificar certificados
sudo kubeadm certs check-expiration
```

**Solución - Rollback Emergency:**
```bash
# 1. Restaurar desde backup de etcd (ver Lab 01)
sudo /path/to/restore-etcd.sh /var/lib/etcd-backup/snapshot-pre-upgrade-*.db

# 2. O reiniciar componentes manualmente
sudo systemctl restart kubelet

# 3. Verificar manifests estáticos
ls -l /etc/kubernetes/manifests/
```

---

## 📚 Recursos Adicionales

### Documentación Oficial

- [Kubernetes Upgrade Documentation](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
- [Version Skew Policy](https://kubernetes.io/releases/version-skew-policy/)
- [kubeadm upgrade](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-upgrade/)

### Comandos Rápidos de Referencia

```bash
# Ver versiones disponibles
apt-cache madison kubeadm

# Plan de upgrade
sudo kubeadm upgrade plan

# Aplicar upgrade (control plane)
sudo kubeadm upgrade apply v1.28.0

# Upgrade node (workers)
sudo kubeadm upgrade node

# Drenar nodo
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data

# Uncordon nodo
kubectl uncordon <node>

# Verificar versiones
kubectl get nodes -o wide
```

### Script de Rollback

En caso de problemas críticos:

```bash
./rollback-upgrade.sh
```

El script:
1. Detiene kubelet en todos los nodos
2. Restaura etcd desde backup pre-upgrade
3. Downgrade de paquetes a versión anterior
4. Reinicia componentes
5. Verifica funcionalidad

---

## 🎓 Conceptos para el Examen CKA

### Puntos Críticos para CKA

1. **Orden de upgrade** (MEMORIZAR):
   ```
   1. Control Plane (kubeadm upgrade apply)
   2. Control Plane kubelet
   3. Worker Nodes (uno por uno)
   ```

2. **Comandos esenciales**:
   ```bash
   # Control Plane
   kubeadm upgrade plan
   kubeadm upgrade apply v1.X.Y
   
   # Workers
   kubeadm upgrade node
   ```

3. **Drenar nodos**:
   ```bash
   kubectl drain <node> --ignore-daemonsets
   kubectl uncordon <node>
   ```

4. **Actualizar paquetes**:
   ```bash
   apt-mark unhold kubeadm kubelet kubectl
   apt-get install kubeadm=1.X.Y-00
   apt-mark hold kubeadm kubelet kubectl
   ```

### Escenario Típico de Examen

**Tarea:**
> "Upgrade el cluster de v1.27.0 a v1.28.0. Primero el control plane, luego worker-01"

**Solución en 10 pasos** (~12-15 minutos):

```bash
# CONTROL PLANE
1. ssh control-plane-node
2. sudo apt-mark unhold kubeadm && sudo apt-get update && sudo apt-get install -y kubeadm=1.28.0-00 && sudo apt-mark hold kubeadm
3. sudo kubeadm upgrade apply v1.28.0 -y
4. kubectl drain control-plane --ignore-daemonsets
5. sudo apt-mark unhold kubelet kubectl && sudo apt-get install -y kubelet=1.28.0-00 kubectl=1.28.0-00 && sudo apt-mark hold kubelet kubectl
6. sudo systemctl daemon-reload && sudo systemctl restart kubelet
7. kubectl uncordon control-plane

# WORKER NODE
8. kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data
9. ssh worker-01
10. sudo apt-mark unhold kubeadm && sudo apt-get install -y kubeadm=1.28.0-00 && sudo kubeadm upgrade node && sudo apt-mark unhold kubelet kubectl && sudo apt-get install -y kubelet=1.28.0-00 kubectl=1.28.0-00 && sudo systemctl daemon-reload && sudo systemctl restart kubelet
11. kubectl uncordon worker-01
12. kubectl get nodes  # Verificar
```

**Tiempo en examen**: 12-18 minutos

---

## 🧹 Limpieza del Laboratorio

```bash
# Ejecutar script de limpieza
./cleanup.sh
```

El script realizará:
- ✅ Verificar que el upgrade se completó exitosamente
- ✅ Limpiar recursos de prueba
- ✅ Documentar versiones finales
- ✅ Crear registro de upgrade

⚠️ **IMPORTANTE**: NO ejecutar cleanup si el upgrade falló. Primero hacer rollback.

---

## 📊 Resumen del Laboratorio

### Lo que Aprendiste

- ✅ Planificar upgrades con `kubeadm upgrade plan`
- ✅ Ejecutar upgrades de control plane
- ✅ Actualizar worker nodes sin downtime
- ✅ Manejar version skew policy
- ✅ Troubleshooting de problemas de upgrade
- ✅ Crear rollback plans

### Tiempo por Fase

| Fase | Tiempo |
|------|--------|
| **Preparación** | 5-10 min |
| **Control Plane** | 10-15 min |
| **Worker Node 1** | 8-12 min |
| **Worker Node 2** | 8-12 min |
| **Verificación** | 5-10 min |
| **TOTAL** | ~40-60 min |

---

## 🎯 Siguiente Paso

Continúa con: **[Lab 03: Node Drain & Cordon](../lab-03-node-drain-cordon/README.md)**

Aprenderás a:
- Realizar mantenimiento de nodos sin downtime
- Usar drain, cordon, uncordon efectivamente
- Manejar PodDisruptionBudgets
- Gestionar node taints y tolerations

---

**🎓 ¡Excelente trabajo!** Has completado un upgrade completo de cluster Kubernetes.

**Nivel de complejidad**: ⭐⭐⭐ Avanzado  
**Relevancia CKA**: 🔴 CRÍTICO (25% del examen - Cluster Maintenance)  
**Habilidades adquiridas**: Cluster upgrade, version management, zero-downtime operations

---

*Laboratorio creado para el curso Kubernetes CKA/CKAD - Módulo 23: Maintenance & Upgrades*  
*Versión: 1.0 | Fecha: 2025-11-13*
