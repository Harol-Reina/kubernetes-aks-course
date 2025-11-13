# Ejemplos de Mantenimiento y Upgrades

Este directorio contiene scripts, configuraciones y ejemplos prácticos para el mantenimiento y upgrade de clusters Kubernetes.

## 📁 Contenido

### Scripts de Automatización

#### 1. upgrade-cluster.sh
Script completo para automatizar el upgrade del control plane.

**Características:**
- Backup automático de etcd y configuraciones
- Verificaciones pre-upgrade
- Upgrade de kubeadm, kubelet, kubectl
- Drain y uncordon automático
- Logging completo
- Dry-run mode

**Uso:**
```bash
# Upgrade básico
sudo ./upgrade-cluster.sh 1.28.4

# Dry-run (solo ver qué pasaría)
sudo ./upgrade-cluster.sh 1.28.4 --dry-run

# Sin backup (NO recomendado)
sudo ./upgrade-cluster.sh 1.28.4 --skip-backup
```

**Requisitos:**
- Ejecutar como root
- Acceso a kubectl configurado
- Conectividad al cluster

---

#### 2. safe-drain.sh
Script avanzado para drenar nodos con verificaciones y reintentos.

**Características:**
- Verificación de PodDisruptionBudgets
- Detección de StatefulSets
- Reintentos automáticos
- Configuración de timeouts
- Verificación post-drain
- Dependency check (jq)

**Uso:**
```bash
# Drain básico
./safe-drain.sh worker-01

# Con timeouts personalizados
./safe-drain.sh worker-01 --grace-period 600 --timeout 900

# Force drain (pods sin controller)
./safe-drain.sh worker-01 --force

# Dry-run
./safe-drain.sh worker-01 --dry-run
```

**Opciones:**
```
-g, --grace-period <seconds>   Grace period para terminación de pods (default: 300)
-t, --timeout <seconds>        Timeout total para drain (default: 600)
-r, --retries <number>         Reintentos máximos (default: 3)
-f, --force                    Forzar eliminación de pods standalone
--no-delete-emptydir           No eliminar pods con emptyDir
--no-ignore-daemonsets         No ignorar DaemonSets (fallará)
```

---

#### 3. cert-monitor.sh
Script para monitorear expiración de certificados y renovarlos automáticamente.

**Características:**
- Verificación de todos los certificados
- Alertas configurables
- Renovación automática opcional
- Email notifications
- Generación de reportes
- Logging

**Uso:**
```bash
# Check básico
sudo ./cert-monitor.sh

# Con threshold de 30 días
sudo ./cert-monitor.sh --alert-days 30

# Auto-renovar si es necesario
sudo ./cert-monitor.sh --renew

# Con email alerts
sudo ./cert-monitor.sh --email admin@example.com --alert-days 60
```

**Configuración de Cron:**
```bash
# Verificar diariamente a las 2 AM
0 2 * * * /usr/local/bin/cert-monitor.sh --alert-days 90 >> /var/log/cert-monitor.log 2>&1
```

---

### Configuraciones

#### 4. pdb-examples.yaml
Ejemplos de PodDisruptionBudgets para diferentes casos de uso.

**Incluye:**
- PDB con `minAvailable` (mínimo de pods disponibles)
- PDB con `maxUnavailable` (máximo de pods no disponibles)
- PDB con porcentajes ("50%")
- PDB para StatefulSets
- PDB muy restrictivo (evitar disrupción)
- PDB para maintenance windows

**Aplicar:**
```bash
# Aplicar todos
kubectl apply -f pdb-examples.yaml

# Verificar
kubectl get pdb --all-namespaces

# Ver detalles
kubectl describe pdb critical-app-pdb -n production
```

**Casos de uso:**
```yaml
# Ejemplo 1: Mínimo 2 pods siempre disponibles
minAvailable: 2

# Ejemplo 2: Máximo 1 pod no disponible
maxUnavailable: 1

# Ejemplo 3: Al menos 50% de pods disponibles
minAvailable: "50%"

# Ejemplo 4: Evitar CUALQUIER disrupción
minAvailable: "100%"
```

---

#### 5. kubeadm-upgrade-config.yaml
Configuración completa de kubeadm para upgrades con HA.

**Incluye:**
- `ClusterConfiguration`: Config del cluster (API server, etcd, networking)
- `InitConfiguration`: Config de bootstrap para primer master
- `KubeletConfiguration`: Config de kubelet (cgroup, resources, eviction)
- `KubeProxyConfiguration`: Config de kube-proxy (IPVS mode)

**Uso durante upgrade:**
```bash
# Aplicar configuración personalizada durante upgrade
sudo kubeadm upgrade apply v1.28.4 --config kubeadm-upgrade-config.yaml

# Ver diferencias antes de aplicar
sudo kubeadm upgrade diff v1.28.4
```

**Personalizar:**
```yaml
# Cambiar versión
kubernetesVersion: v1.28.4

# Cambiar control plane endpoint (HA)
controlPlaneEndpoint: "k8s-lb.example.com:6443"

# Cambiar pod subnet
networking:
  podSubnet: "10.244.0.0/16"
```

---

#### 6. pre-upgrade-checklist.md
Checklist exhaustivo de 100+ items para upgrades seguros.

**Secciones:**
1. **Planning Phase** (15 items)
   - Documentation review
   - Version verification
   - Cluster health check
   - Capacity planning

2. **Backup Phase** (12 items)
   - etcd backup
   - Configuration backup
   - Resource backup

3. **Testing Phase** (7 items)
   - Staging environment
   - Communication

4. **Upgrade Phase** (35 items)
   - Pre-upgrade actions
   - Control plane upgrade
   - CNI plugin upgrade
   - Worker nodes upgrade

5. **Post-Upgrade Verification** (25 items)
   - Cluster verification
   - Application verification
   - Smoke tests
   - Certificate check
   - Monitoring

6. **Documentation & Cleanup** (6 items)

**Uso:**
```bash
# Imprimir checklist
cat pre-upgrade-checklist.md

# Crear copia para marcar durante upgrade
cp pre-upgrade-checklist.md /tmp/upgrade-$(date +%Y%m%d)-checklist.md

# Marcar items con [x]
# - [ ] Item pendiente
# - [x] Item completado
```

---

## 🚀 Workflow Recomendado

### Upgrade Completo del Cluster

```bash
# 1. Revisar checklist
cat pre-upgrade-checklist.md

# 2. Monitorear certificados
sudo ./cert-monitor.sh

# 3. Crear PDBs para apps críticas
kubectl apply -f pdb-examples.yaml

# 4. Upgrade control plane (primer master)
sudo ./upgrade-cluster.sh 1.28.4

# Si HA, upgrade masters adicionales:
ssh k8s-master-02 'sudo kubeadm upgrade node'
# ... repetir para cada master

# 5. Upgrade cada worker
for worker in worker-01 worker-02 worker-03; do
  ./safe-drain.sh $worker
  
  ssh $worker 'sudo apt-mark unhold kubeadm kubelet kubectl && \
               sudo apt-get update && \
               sudo apt-get install -y kubeadm=1.28.4-00 kubelet=1.28.4-00 kubectl=1.28.4-00 && \
               sudo apt-mark hold kubeadm kubelet kubectl && \
               sudo kubeadm upgrade node && \
               sudo systemctl daemon-reload && \
               sudo systemctl restart kubelet'
  
  kubectl uncordon $worker
  
  echo "Waiting 30s before next worker..."
  sleep 30
done

# 6. Verificar
kubectl get nodes -o wide
kubectl get pods --all-namespaces | grep -v Running
```

---

## 📚 Best Practices

### Scripts
- ✅ Siempre usar dry-run primero
- ✅ Ejecutar en tmux/screen (evitar desconexiones)
- ✅ Revisar logs después de ejecución
- ✅ Tener segunda terminal para troubleshooting

### PodDisruptionBudgets
- ✅ Crear PDBs ANTES de drain
- ✅ No usar `minAvailable: "100%"` a menos que realmente necesario
- ✅ Preferir `maxUnavailable: 1` para rolling updates
- ✅ Considerar porcentajes para auto-scaling apps

### Upgrades
- ✅ Siempre backup antes de upgrade
- ✅ Un nodo a la vez (workers)
- ✅ Esperar a que pods reschedulen antes de siguiente nodo
- ✅ Monitorear continuamente durante upgrade
- ✅ Tener plan de rollback

### Certificados
- ✅ Renovar cuando falten 90 días
- ✅ Automatizar monitoreo con cron
- ✅ Backup antes de renovar
- ✅ Reiniciar kubelet después de renovar

---

## 🐛 Troubleshooting

### Script upgrade-cluster.sh falla

**Problema:** Script se detiene en etcd backup
```bash
# Verificar etcd
sudo ETCDCTL_API=3 etcdctl endpoint health

# Saltar backup (NO recomendado)
sudo ./upgrade-cluster.sh 1.28.4 --skip-backup
```

**Problema:** kubeadm upgrade apply falla
```bash
# Ver logs detallados
sudo kubeadm upgrade apply v1.28.4 -v=5

# Verificar certificados
sudo kubeadm certs check-expiration
```

### safe-drain.sh se queda stuck

**Problema:** PDB muy restrictivo
```bash
# Ver PDBs
kubectl get pdb --all-namespaces

# Editar temporalmente
kubectl edit pdb <pdb-name>
# Cambiar minAvailable o maxUnavailable

# Reintentar drain
./safe-drain.sh <node> --retries 5
```

**Problema:** Pods no pueden ser evacuados
```bash
# Forzar drain
./safe-drain.sh <node> --force --delete-emptydir-data
```

### cert-monitor.sh no funciona

**Problema:** Error de permisos
```bash
# Debe ejecutarse como root
sudo ./cert-monitor.sh
```

**Problema:** Mail no funciona
```bash
# Instalar mailutils
sudo apt-get install mailutils

# O usar sin email
./cert-monitor.sh --check-only
```

---

## 📖 Referencias

- [Upgrading kubeadm clusters](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
- [Safely Drain Node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)
- [Certificate Management](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)
- [PodDisruptionBudget](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)

---

## ✅ Validación de Scripts

```bash
# Verificar permisos ejecutables
chmod +x *.sh

# Verificar sintaxis bash
bash -n upgrade-cluster.sh
bash -n safe-drain.sh
bash -n cert-monitor.sh

# Verificar YAML
kubectl apply -f pdb-examples.yaml --dry-run=client
kubectl apply -f kubeadm-upgrade-config.yaml --dry-run=client
```

---

**Ver también:**
- [README principal](../README.md)
- [Laboratorios](../laboratorios/README.md)
- [RESUMEN](../RESUMEN-MODULO.md)
