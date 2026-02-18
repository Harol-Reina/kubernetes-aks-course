# Lab 01: Cluster Upgrade - 1.27.x → 1.28.x

**Duración estimada:** 60-90 minutos  
**Dificultad:** ⭐⭐⭐ (Intermedio-Avanzado)  
**Prerequisitos:** Cluster funcional en 1.27.x con kubectl y kubeadm instalados

## 🎯 Objetivos

Al completar este laboratorio, serás capaz de:

- Planificar y ejecutar un upgrade de cluster Kubernetes
- Realizar backup completo de etcd antes del upgrade
- Upgrader control plane y worker nodes de forma segura
- Verificar la integridad del cluster post-upgrade
- Aplicar version skew policy correctamente

## 📋 Arquitectura

```
┌───────────────────────────────────────────────────────────┐
│                    Cluster Upgrade                         │
│                                                            │
│  1.27.x                          1.28.x                   │
│                                                            │
│  ┌─────────────┐               ┌─────────────┐           │
│  │  Master     │   Upgrade →   │  Master     │           │
│  │  v1.27.8    │               │  v1.28.4    │           │
│  └─────────────┘               └─────────────┘           │
│         │                               │                 │
│    ┌────┴────┐                     ┌────┴────┐           │
│    │         │                     │         │           │
│ ┌──▼───┐ ┌──▼───┐             ┌──▼───┐ ┌──▼───┐        │
│ │Worker│ │Worker│  Upgrade    │Worker│ │Worker│        │
│ │v1.27 │ │v1.27 │     →       │v1.28 │ │v1.28 │        │
│ └──────┘ └──────┘             └──────┘ └──────┘        │
└───────────────────────────────────────────────────────────┘
```

## ⚙️ Preparación

### Verificar Versión Actual

```bash
# Ver versión de nodos
kubectl get nodes -o wide

# Ver versión de componentes
kubectl version --short
kubeadm version

# Debería mostrar algo como:
# Server Version: v1.27.8
# kubeadm version: v1.27.8
```

---

## 🧪 Paso 1: Pre-Upgrade Checks (15 min)

### 1.1 Health Check del Cluster

```bash
# Verificar todos los nodos Ready
kubectl get nodes

# Verificar pods del sistema
kubectl get pods -n kube-system

# Buscar problemas
kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded

# Verificar eventos recientes
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

**✅ Checkpoint:** Todos los nodos Ready, todos los pods Running/Succeeded.

### 1.2 Revisar Release Notes

```bash
# Abrir release notes de 1.28
# https://kubernetes.io/docs/setup/release/notes/

# Buscar:
# - Breaking changes
# - Deprecated APIs
# - Upgrade path (debe ser 1.27 → 1.28 directamente)
```

### 1.3 Verificar Espacio en Disco

```bash
# En cada nodo
df -h /var/lib/etcd
df -h /var/lib/kubelet

# Debe haber al menos 10GB libre en cada
```

**✅ Checkpoint:** Espacio suficiente en todos los nodos.

---

## 💾 Paso 2: Backup Completo (15 min)

### 2.1 Backup de etcd

```bash
# En el control plane
BACKUP_DIR="/backup/upgrade-$(date +%Y%m%d-%H%M%S)"
sudo mkdir -p $BACKUP_DIR

# Crear snapshot de etcd
sudo ETCDCTL_API=3 etcdctl snapshot save ${BACKUP_DIR}/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verificar snapshot
sudo ETCDCTL_API=3 etcdctl snapshot status ${BACKUP_DIR}/etcd-snapshot.db --write-out=table

# Output esperado:
# +----------+----------+------------+------------+
# |   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
# +----------+----------+------------+------------+
# | 12345678 |   123456 |       1000 |     10 MB  |
# +----------+----------+------------+------------+
```

### 2.2 Backup de Configuraciones

```bash
# Backup de /etc/kubernetes
sudo tar -czf ${BACKUP_DIR}/kubernetes-configs.tar.gz /etc/kubernetes

# Backup de kubelet config
sudo cp /var/lib/kubelet/config.yaml ${BACKUP_DIR}/kubelet-config.yaml

# Verificar backups
ls -lh $BACKUP_DIR
```

### 2.3 Backup de Recursos

```bash
# Exportar todos los recursos
kubectl get all --all-namespaces -o yaml > ${BACKUP_DIR}/all-resources.yaml

# Exportar CRDs
kubectl get crd -o yaml > ${BACKUP_DIR}/crds.yaml

# Verificar
wc -l ${BACKUP_DIR}/*.yaml
```

**✅ Checkpoint:** Backups creados y verificados. Anota la ruta: ________________

---

## ⬆️ Paso 3: Upgrade Control Plane (20 min)

### 3.1 Upgrade kubeadm

```bash
# Ver versiones disponibles
sudo apt update
sudo apt-cache madison kubeadm | grep 1.28

# Desbloquear y upgrade kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.4-00
sudo apt-mark hold kubeadm

# Verificar versión
kubeadm version
# Debe mostrar: v1.28.4
```

### 3.2 Plan de Upgrade

```bash
# Ver qué se va a upgradar
sudo kubeadm upgrade plan

# Output mostrará:
# - Versión actual: v1.27.8
# - Versión target: v1.28.4
# - Componentes a actualizar
# - Advertencias si las hay
```

**⚠️ IMPORTANTE:** Lee el output completamente. Busca warnings o errors.

### 3.3 Aplicar Upgrade

```bash
# Aplicar upgrade del control plane
sudo kubeadm upgrade apply v1.28.4 -y

# Este comando tardará 5-10 minutos
# Actualiza:
# - kube-apiserver
# - kube-controller-manager
# - kube-scheduler
# - kube-proxy
# - CoreDNS
# - etcd (si stacked)

# Buscar mensaje:
# [upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.28.4". Enjoy!
```

**✅ Checkpoint:** Upgrade apply completado sin errores.

### 3.4 Drain Control Plane Node

```bash
# Obtener nombre del control plane
CONTROL_PLANE=$(kubectl get nodes --selector=node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}')

# Drain (si schedulable)
kubectl drain $CONTROL_PLANE --ignore-daemonsets --delete-emptydir-data

# Output:
# node/<node-name> cordoned
# node/<node-name> drained
```

### 3.5 Upgrade kubelet y kubectl

```bash
# Upgrade kubelet y kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get update
sudo apt-get install -y kubelet=1.28.4-00 kubectl=1.28.4-00
sudo apt-mark hold kubelet kubectl

# Reiniciar kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Verificar status
sudo systemctl status kubelet
```

### 3.6 Uncordon Control Plane

```bash
# Reactivar scheduling
kubectl uncordon $CONTROL_PLANE

# Verificar
kubectl get nodes
```

**✅ Checkpoint:** Control plane mostrando v1.28.4 en `kubectl get nodes`.

---

## 👷 Paso 4: Upgrade Worker Nodes (30 min)

Repetir para cada worker node **UNO A LA VEZ**.

### 4.1 Worker 1

#### En CONTROL PLANE:

```bash
# Drain worker-01
kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data --force

# Ver que pods migraron
watch kubectl get pods -o wide --all-namespaces
# Ctrl+C cuando no veas pods en worker-01
```

#### SSH a WORKER-01:

```bash
ssh worker-01

# Upgrade kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.4-00
sudo apt-mark hold kubeadm

# Upgrade configuración del nodo
sudo kubeadm upgrade node

# Upgrade kubelet y kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get update
sudo apt-get install -y kubelet=1.28.4-00 kubectl=1.28.4-00
sudo apt-mark hold kubelet kubectl

# Reiniciar kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Verificar
sudo systemctl status kubelet

# Salir del worker
exit
```

#### De vuelta en CONTROL PLANE:

```bash
# Uncordon worker-01
kubectl uncordon worker-01

# Verificar versión
kubectl get nodes -o wide
# worker-01 debe mostrar v1.28.4

# Esperar a que pods reschedulen
watch kubectl get pods -o wide --all-namespaces
# Ctrl+C cuando veas pods en worker-01
```

**✅ Checkpoint:** Worker-01 en v1.28.4 y con pods running.

### 4.2 Worker 2 (Repetir Proceso)

```bash
# Drain
kubectl drain worker-02 --ignore-daemonsets --delete-emptydir-data --force

# SSH y upgrade (mismos comandos que worker-01)
ssh worker-02
# ... comandos de upgrade ...
exit

# Uncordon
kubectl uncordon worker-02

# Verificar
kubectl get nodes -o wide
```

**⚠️ TIP:** Si tienes más de 2 workers, continúa uno por uno. NO draines múltiples workers simultáneamente a menos que tengas capacidad suficiente.

**✅ Checkpoint:** Todos los workers en v1.28.4.

---

## ✅ Paso 5: Verificación Post-Upgrade (15 min)

### 5.1 Verificar Versiones

```bash
# Ver todas las versiones de nodos
kubectl get nodes -o wide

# Output esperado:
# NAME              STATUS   ROLES           AGE   VERSION
# k8s-master-01     Ready    control-plane   30d   v1.28.4
# worker-01         Ready    <none>          30d   v1.28.4
# worker-02         Ready    <none>          30d   v1.28.4

# Verificar versión de API server
kubectl version --short

# Output:
# Server Version: v1.28.4
```

### 5.2 Verificar Pods del Sistema

```bash
# Ver todos los pods de kube-system
kubectl get pods -n kube-system

# Verificar que todos estén Running
kubectl get pods -n kube-system --field-selector=status.phase!=Running

# No debe haber output (todos Running)
```

### 5.3 Verificar Componentes

```bash
# Ver pods del control plane
kubectl get pods -n kube-system -l tier=control-plane

# Debe mostrar:
# - kube-apiserver
# - kube-controller-manager
# - kube-scheduler
# - etcd (si stacked)

# Verificar logs (últimas 20 líneas)
kubectl logs -n kube-system -l component=kube-apiserver --tail=20
kubectl logs -n kube-system -l component=kube-controller-manager --tail=20
```

### 5.4 Smoke Test

```bash
# Crear deployment de prueba
kubectl create deployment test-upgrade --image=nginx:latest --replicas=3

# Verificar
kubectl get deployment test-upgrade
kubectl get pods -l app=test-upgrade -o wide

# Exponer como servicio
kubectl expose deployment test-upgrade --port=80 --type=NodePort

# Verificar servicio
kubectl get svc test-upgrade

# Test de conectividad
NODE_PORT=$(kubectl get svc test-upgrade -o jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

curl http://$NODE_IP:$NODE_PORT
# Debe mostrar página de bienvenida de nginx

# Cleanup
kubectl delete deployment test-upgrade
kubectl delete svc test-upgrade
```

### 5.5 Verificar Certificados

```bash
# Verificar expiración de certificados
sudo kubeadm certs check-expiration

# Todos deben tener >365 días
```

### 5.6 Verificar etcd

```bash
# Health de etcd
sudo ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Output:
# https://127.0.0.1:2379 is healthy: successfully committed proposal: took = 2.3ms
```

**✅ Checkpoint:** Todos los tests pasados.

---

## 🎓 Desafíos Adicionales

### Challenge 1: Verificar Deprecations

```bash
# Instalar kubectl-convert plugin
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert"
chmod +x kubectl-convert
sudo mv kubectl-convert /usr/local/bin/

# Buscar APIs deprecadas en recursos
kubectl get all --all-namespaces -o yaml | kubectl-convert -f - --output-version <new-api>
```

### Challenge 2: Automatizar con Script

Crea un script que:
- Verifique pre-requisitos
- Haga backup automático
- Upgrade todos los nodos
- Verifique post-upgrade

Usa `../scripts/upgrade-cluster.sh` como referencia.

### Challenge 3: Upgrade HA Cluster

Si tienes múltiples masters:

```bash
# En masters adicionales (NO el primero)
sudo kubeadm upgrade node

# Drain, upgrade kubelet, uncordon (igual que workers)
```

---

## 🐛 Troubleshooting

### Problema: kubeadm upgrade apply falla

```bash
# Ver logs detallados
sudo kubeadm upgrade apply v1.28.4 -v=5

# Verificar etcd health
sudo ETCDCTL_API=3 etcdctl endpoint health

# Verificar espacio en disco
df -h
```

### Problema: Pods no schedulan después de upgrade

```bash
# Verificar que nodos no están cordoned
kubectl get nodes
# Si STATUS = SchedulingDisabled

# Uncordon
kubectl uncordon <node-name>
```

### Problema: kubelet no inicia después de upgrade

```bash
# Ver logs
sudo journalctl -u kubelet -f

# Errores comunes:
# 1. Swap habilitado
sudo swapoff -a

# 2. Cgroup driver mismatch
# Verificar /var/lib/kubelet/config.yaml
# cgroupDriver debe ser "systemd"

# Reiniciar
sudo systemctl restart kubelet
```

---

## ✅ Criterios de Completitud

- [ ] Versión 1.27.x verificada al inicio
- [ ] Backups completos creados (etcd, configs, resources)
- [ ] Control plane upgraded a 1.28.4
- [ ] Todos los workers upgraded a 1.28.4
- [ ] Todos los nodos muestran Ready en kubectl get nodes
- [ ] Todos los pods de kube-system Running
- [ ] Smoke test exitoso (nginx deployment)
- [ ] Certificados válidos (>365 días)
- [ ] etcd saludable
- [ ] Sin errores en eventos: kubectl get events | grep -i error

---

## 📚 Referencias

- [Upgrading kubeadm clusters](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
- [Version Skew Policy](https://kubernetes.io/releases/version-skew-policy/)
- [Release Notes 1.28](https://kubernetes.io/docs/setup/release/notes/)

---

**🎯 Objetivo CKA:** Este lab cubre ~10% del examen CKA (Cluster Architecture, Installation & Configuration).
