# Módulo 23: Cluster Maintenance & Upgrades

## 📋 Tabla de Contenidos

1. [Introducción](#introducción)
2. [Estrategia de Upgrades](#estrategia-de-upgrades)
3. [Version Skew Policy](#version-skew-policy)
4. [Upgrade del Control Plane](#upgrade-del-control-plane)
5. [Upgrade de Worker Nodes](#upgrade-de-worker-nodes)
6. [Node Maintenance](#node-maintenance)
7. [Certificate Management](#certificate-management)
8. [Backup y Rollback](#backup-y-rollback)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

---

## 🎯 Objetivos de Aprendizaje

Al completar este módulo, serás capaz de:

- ✅ Planificar y ejecutar upgrades de cluster seguros
- ✅ Entender y aplicar version skew policy
- ✅ Realizar upgrades de control plane con kubeadm
- ✅ Actualizar worker nodes sin downtime
- ✅ Usar `drain`, `cordon`, y `uncordon` efectivamente
- ✅ Gestionar certificados de Kubernetes
- ✅ Implementar estrategias de backup pre-upgrade
- ✅ Realizar rollback en caso de problemas

---

## 📚 Introducción

### ¿Por Qué Hacer Upgrades?

Los upgrades de Kubernetes son esenciales para:

1. **Seguridad**
   - Parches de vulnerabilidades críticas
   - CVEs y security fixes
   - Actualizaciones de dependencias

2. **Nuevas Características**
   - APIs mejoradas
   - Nuevas funcionalidades
   - Performance improvements

3. **Soporte**
   - Kubernetes soporta las últimas 3 minor versions
   - EOL (End of Life) de versiones antiguas
   - Soporte de la comunidad

4. **Compatibilidad**
   - Plugins y addons requieren versiones específicas
   - Integración con otros sistemas
   - Cloud provider compatibility

### Tipos de Upgrades

```
┌─────────────────────────────────────────────────────────┐
│                    Upgrade Types                         │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. PATCH (1.28.0 → 1.28.1)                             │
│     - Bug fixes                                          │
│     - Security patches                                   │
│     - Safe, minimal risk                                 │
│     - No breaking changes                                │
│                                                          │
│  2. MINOR (1.28.x → 1.29.0)                             │
│     - New features                                       │
│     - API changes (may deprecate)                        │
│     - More risk, requires testing                        │
│     - ONE minor version at a time                        │
│                                                          │
│  3. MAJOR (1.x → 2.0)                                   │
│     - Breaking changes                                   │
│     - Major redesign                                     │
│     - Extensive testing required                         │
│     - Not yet occurred in K8s history                    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Frecuencia de Upgrades

**Recomendaciones:**

- **Patch releases**: Inmediatamente (especialmente security fixes)
- **Minor releases**: Cada 3-6 meses
- **Testing**: Siempre en staging antes de production
- **Maintenance windows**: Planificar con antelación

---

## 🔄 Estrategia de Upgrades

### Flujo de Upgrade Completo

```
┌────────────────────────────────────────────────────────────────┐
│                    Upgrade Workflow                            │
└────────────────────────────────────────────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  1. Planning  │
                    │  - Check docs │
                    │  - Test plan  │
                    │  - Backup     │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  2. Backup    │
                    │  - etcd       │
                    │  - Configs    │
                    │  - Resources  │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │ 3. Upgrade CP │
                    │ - First master│
                    │ - Other masters│
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │4. Upgrade CNI │
                    │ - If needed   │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │5. Upgrade     │
                    │   Workers     │
                    │ - One by one  │
                    │ - Or rolling  │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │ 6. Validation │
                    │ - Smoke tests │
                    │ - Monitoring  │
                    └───────────────┘
```

### Pre-Upgrade Checklist

```bash
# 1. Verificar versión actual
kubectl version --short
kubeadm version

# 2. Ver release notes de versión objetivo
# https://kubernetes.io/docs/setup/release/notes/

# 3. Verificar health del cluster
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get componentstatuses  # Deprecated en 1.28+

# 4. Backup de etcd
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db

# 5. Backup de configuraciones
sudo cp -r /etc/kubernetes /backup/kubernetes-configs
kubectl get all --all-namespaces -o yaml > /backup/all-resources.yaml

# 6. Verificar que no hay pods en Pending o Error
kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded

# 7. Verificar espacio en disco
df -h

# 8. Documentar versiones de addons
kubectl get deployments -n kube-system -o wide
```

---

## 📏 Version Skew Policy

### Reglas de Compatibilidad

Kubernetes tiene políticas estrictas de compatibilidad entre componentes:

```
┌─────────────────────────────────────────────────────────────┐
│              Version Skew Policy (v1.28)                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  kube-apiserver        1.28                                  │
│  (Master)              │                                     │
│                        │                                     │
│  kube-controller-      1.27 - 1.28                          │
│  manager               (n-1 to n)                           │
│                        │                                     │
│  kube-scheduler        1.27 - 1.28                          │
│                        (n-1 to n)                           │
│                        │                                     │
│  kubelet               1.26 - 1.28                          │
│  (Workers)             (n-2 to n)                           │
│                        │                                     │
│  kube-proxy            1.26 - 1.28                          │
│                        (n-2 to n)                           │
│                        │                                     │
│  kubectl               1.27 - 1.29                          │
│                        (n-1 to n+1)                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Reglas Clave:**

1. **API Server** es siempre la versión más nueva
2. **Controller Manager y Scheduler**: Pueden ser 1 minor version atrás
3. **kubelet**: Puede ser hasta 2 minor versions atrás
4. **kube-proxy**: Sigue las mismas reglas que kubelet
5. **kubectl**: Puede ser 1 version adelante o atrás

### Orden de Upgrade

⚠️ **CRÍTICO**: Siempre seguir este orden:

```
1. etcd (si external)
2. Control Plane (API server primero)
3. Cloud Controller Manager (si aplica)
4. CNI plugins (si requiere actualización)
5. CoreDNS
6. kube-proxy
7. Worker nodes
```

### Restricciones de Skipping

❌ **NO PUEDES:**
- Saltar minor versions: `1.27 → 1.29` (PROHIBIDO)
- Downgrade: `1.28 → 1.27` (NO SOPORTADO oficialmente)

✅ **PUEDES:**
- Upgrade secuencial: `1.27 → 1.28 → 1.29`
- Upgrade de patches: `1.28.0 → 1.28.5` (sin restricciones)

---

## 🎮 Upgrade del Control Plane

### Proceso con kubeadm

#### Paso 1: Upgrade del Primer Master

```bash
# En el PRIMER control plane node

# 1. Ver versión actual
kubectl version --short
kubeadm version

# 2. Verificar versiones disponibles
sudo apt update
sudo apt-cache madison kubeadm | head -20

# 3. Upgrade de kubeadm
# Ejemplo: Upgrade a 1.28.4
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.4-00
sudo apt-mark hold kubeadm

# 4. Verificar versión de kubeadm
kubeadm version

# 5. Planificar upgrade (dry-run)
sudo kubeadm upgrade plan

# Output muestra:
# - Versión actual
# - Versión target
# - Componentes a actualizar
# - Advertencias si las hay

# 6. Aplicar upgrade
sudo kubeadm upgrade apply v1.28.4

# Este comando:
# - Actualiza certificados si es necesario
# - Actualiza manifiestos estáticos
# - Actualiza configuración de kubelet
# - Actualiza etcd
# - Actualiza CoreDNS
# - Actualiza kube-proxy

# 7. Drain del nodo (si scheduling habilitado)
kubectl drain <control-plane-node> --ignore-daemonsets

# 8. Upgrade de kubelet y kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get update
sudo apt-get install -y kubelet=1.28.4-00 kubectl=1.28.4-00
sudo apt-mark hold kubelet kubectl

# 9. Reiniciar kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# 10. Uncordon del nodo
kubectl uncordon <control-plane-node>

# 11. Verificar upgrade
kubectl get nodes
# NAME              STATUS   ROLES           AGE   VERSION
# k8s-master-01     Ready    control-plane   30d   v1.28.4  ✓
```

#### Paso 2: Upgrade de Control Planes Adicionales (HA)

Si tienes cluster HA con múltiples masters:

```bash
# En cada control plane ADICIONAL (NO el primero)

# 1. Upgrade kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.4-00
sudo apt-mark hold kubeadm

# 2. Upgrade del nodo (NO usar 'apply', usar 'node')
sudo kubeadm upgrade node

# 3. Drain del nodo
kubectl drain <control-plane-node> --ignore-daemonsets

# 4. Upgrade kubelet y kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get update
sudo apt-get install -y kubelet=1.28.4-00 kubectl=1.28.4-00
sudo apt-mark hold kubelet kubectl

# 5. Reiniciar kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# 6. Uncordon del nodo
kubectl uncordon <control-plane-node>

# 7. Verificar
kubectl get nodes
```

### Verificación Post-Upgrade Control Plane

```bash
# 1. Verificar versión de nodos
kubectl get nodes -o wide

# 2. Verificar pods del sistema
kubectl get pods -n kube-system

# 3. Verificar componentes
kubectl get pods -n kube-system -l tier=control-plane

# 4. Verificar versión de API server
kubectl version --short

# 5. Verificar etcd (si stacked)
kubectl get pods -n kube-system -l component=etcd

# 6. Verificar logs de API server
kubectl logs -n kube-system -l component=kube-apiserver --tail=50

# 7. Verificar certificados (si renovados)
sudo kubeadm certs check-expiration

# 8. Test básico de funcionalidad
kubectl run test-upgrade --image=nginx --rm -it -- echo "Upgrade OK"
```

---

## 👷 Upgrade de Worker Nodes

### Estrategias de Upgrade

#### Opción 1: In-Place Upgrade (Recommended)

Actualizar cada nodo uno por uno sin crear nuevos nodos.

**Ventajas:**
- No requiere nuevos nodos
- Más económico
- Mantiene configuraciones

**Desventajas:**
- Requiere drain (downtime de pods)
- Más lento

#### Opción 2: Rolling Replacement

Crear nuevos nodos con nueva versión, migrar workloads, eliminar nodos viejos.

**Ventajas:**
- Zero downtime
- Rollback fácil
- Nodos "limpios"

**Desventajas:**
- Requiere capacidad adicional temporalmente
- Más complejo

### Proceso de Upgrade In-Place

```bash
# Para CADA worker node (uno a la vez)

# 1. En el CONTROL PLANE, drain el worker
kubectl drain <worker-node> \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --force

# Este comando:
# - Marca el nodo como unschedulable (cordon)
# - Evacúa todos los pods (excepto DaemonSets)
# - Espera a que pods terminen gracefully
# - Elimina pods con emptyDir (con --delete-emptydir-data)

# Verificar que pods migraron
kubectl get pods -o wide --all-namespaces | grep <worker-node>
# No debe haber pods (excepto DaemonSets)

# 2. SSH al worker node
ssh user@<worker-node>

# 3. Upgrade kubeadm
sudo apt-mark unhold kubeadm
sudo apt-get update
sudo apt-get install -y kubeadm=1.28.4-00
sudo apt-mark hold kubeadm

# 4. Upgrade configuración del nodo
sudo kubeadm upgrade node

# 5. Upgrade kubelet y kubectl
sudo apt-mark unhold kubelet kubectl
sudo apt-get update
sudo apt-get install -y kubelet=1.28.4-00 kubectl=1.28.4-00
sudo apt-mark hold kubelet kubectl

# 6. Reiniciar kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Verificar status
sudo systemctl status kubelet

# 7. De vuelta en CONTROL PLANE, uncordon el nodo
kubectl uncordon <worker-node>

# 8. Verificar que el nodo está Ready
kubectl get nodes

# 9. Verificar que pods se están schedulando
watch kubectl get pods -o wide --all-namespaces

# 10. Esperar a que todo se estabilice
# Luego proceder con el siguiente worker
```

### Upgrade de Múltiples Workers

Para upgrades más rápidos (con suficiente capacidad):

```bash
# Opción A: Dos a la vez (si tienes 4+ workers)
kubectl drain worker-01 worker-02 --ignore-daemonsets --delete-emptydir-data

# Upgrade worker-01 y worker-02 en paralelo
# ...

kubectl uncordon worker-01 worker-02

# Opción B: Batch upgrade con script
#!/bin/bash
WORKERS=("worker-01" "worker-02" "worker-03" "worker-04")

for worker in "${WORKERS[@]}"; do
  echo "Upgrading $worker..."
  
  # Drain
  kubectl drain $worker --ignore-daemonsets --delete-emptydir-data --force
  
  # SSH y upgrade (requiere passwordless SSH)
  ssh $worker 'sudo apt-mark unhold kubeadm kubelet kubectl && \
               sudo apt-get update && \
               sudo apt-get install -y kubeadm=1.28.4-00 kubelet=1.28.4-00 kubectl=1.28.4-00 && \
               sudo apt-mark hold kubeadm kubelet kubectl && \
               sudo kubeadm upgrade node && \
               sudo systemctl daemon-reload && \
               sudo systemctl restart kubelet'
  
  # Uncordon
  kubectl uncordon $worker
  
  # Esperar a que esté Ready
  kubectl wait --for=condition=Ready node/$worker --timeout=300s
  
  echo "$worker upgraded successfully"
done
```

---

## 🔧 Node Maintenance

### Comandos Esenciales

#### kubectl drain

Evacuar pods de un nodo de forma segura:

```bash
# Uso básico
kubectl drain <node-name>

# Con opciones comunes
kubectl drain <node-name> \
  --ignore-daemonsets \          # Ignorar DaemonSets (calico, kube-proxy, etc.)
  --delete-emptydir-data \       # Permitir eliminación de pods con emptyDir
  --force \                      # Forzar eliminación de pods sin controller
  --grace-period=300 \           # Esperar 5 minutos para graceful shutdown
  --timeout=600s                 # Timeout total de 10 minutos

# Dry-run (ver qué pasaría)
kubectl drain <node-name> --dry-run=client

# Filtrar pods específicos
kubectl drain <node-name> \
  --pod-selector='app!=critical-app'
```

**¿Qué hace drain?**
1. Marca el nodo como `SchedulingDisabled` (cordon)
2. Evacúa pods del nodo:
   - Respeta PodDisruptionBudgets
   - Espera graceful termination
   - Reschedules pods en otros nodos
3. Elimina pods que no pueden ser rescheduled (con --force)

**Casos de uso:**
- Antes de upgrade de nodo
- Antes de reboot
- Antes de mantenimiento de hardware
- Antes de eliminar nodo

#### kubectl cordon

Marcar nodo como no schedulable (sin evacuar pods):

```bash
# Marcar nodo como unschedulable
kubectl cordon <node-name>

# Verificar
kubectl get nodes
# NAME          STATUS                     ROLES    AGE   VERSION
# worker-01     Ready,SchedulingDisabled   <none>   10d   v1.28.4

# Uncordon (reactivar scheduling)
kubectl uncordon <node-name>
```

**¿Cuándo usar cordon?**
- Investigación de problemas (no queremos más pods)
- Mantenimiento que NO requiere reboot
- Testing de capacidad del cluster
- Antes de drain (cordon es parte de drain)

#### kubectl uncordon

Reactivar scheduling en un nodo:

```bash
# Reactivar nodo
kubectl uncordon <node-name>

# Verificar que STATUS vuelve a Ready
kubectl get nodes
```

**Nota:** `uncordon` NO mueve pods de vuelta automáticamente. Los pods existentes permanecen donde fueron rescheduled.

### Escenarios de Mantenimiento

#### Escenario 1: Reboot de Worker Node

```bash
# 1. Drain del nodo
kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data

# 2. SSH al nodo y reboot
ssh worker-01
sudo reboot

# 3. Esperar a que vuelva (verificar con ping o SSH)
ping -c 3 worker-01

# 4. Verificar que kubelet arrancó
ssh worker-01 'sudo systemctl status kubelet'

# 5. Uncordon del nodo
kubectl uncordon worker-01

# 6. Verificar
kubectl get nodes
kubectl get pods -o wide --all-namespaces | grep worker-01
```

#### Escenario 2: Mantenimiento de Hardware

```bash
# 1. Drain del nodo
kubectl drain worker-02 --ignore-daemonsets --delete-emptydir-data --force

# 2. Apagar nodo
ssh worker-02 'sudo shutdown -h now'

# 3. Realizar mantenimiento físico
# - Cambio de disco
# - Upgrade de RAM
# - Etc.

# 4. Encender nodo

# 5. Verificar servicios
ssh worker-02 'sudo systemctl status kubelet containerd'

# 6. Uncordon
kubectl uncordon worker-02
```

#### Escenario 3: Investigación de Problemas

```bash
# 1. Cordon (sin evacuar pods aún)
kubectl cordon worker-03

# 2. Investigar sin que lleguen nuevos pods
kubectl logs -n kube-system -l component=kubelet
ssh worker-03 'sudo journalctl -u kubelet -f'

# 3. Si necesitas evacuar para más investigación
kubectl drain worker-03 --ignore-daemonsets --delete-emptydir-data

# 4. Fix del problema
# ...

# 5. Reactivar
kubectl uncordon worker-03
```

### PodDisruptionBudgets (PDB)

Para proteger aplicaciones críticas durante drain:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: critical-app-pdb
spec:
  minAvailable: 2  # O maxUnavailable: 1
  selector:
    matchLabels:
      app: critical-app
```

```bash
# Crear PDB
kubectl apply -f pdb.yaml

# Ver PDBs
kubectl get pdb

# Drain respetará el PDB (esperará hasta que sea seguro)
kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data
# Esperará hasta que haya al menos 2 pods disponibles antes de evacuar
```

---

## 🔐 Certificate Management

### Certificados en Kubernetes

Kubernetes usa PKI para comunicación segura entre componentes:

```
┌─────────────────────────────────────────────────────────┐
│              Kubernetes Certificates                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  /etc/kubernetes/pki/                                    │
│  ├── ca.crt, ca.key             (Root CA)               │
│  ├── apiserver.crt, apiserver.key                       │
│  ├── apiserver-kubelet-client.crt, .key                 │
│  ├── front-proxy-ca.crt, front-proxy-ca.key             │
│  ├── front-proxy-client.crt, front-proxy-client.key     │
│  ├── sa.key, sa.pub             (Service Account)       │
│  └── etcd/                                               │
│      ├── ca.crt, ca.key         (etcd CA)               │
│      ├── server.crt, server.key                         │
│      ├── peer.crt, peer.key                             │
│      └── healthcheck-client.crt, .key                   │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Verificar Expiración

```bash
# Verificar todos los certificados
sudo kubeadm certs check-expiration

# Output:
# CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY
# admin.conf                 Nov 13, 2026 12:00 UTC   364d            ca
# apiserver                  Nov 13, 2026 12:00 UTC   364d            ca
# apiserver-etcd-client      Nov 13, 2026 12:00 UTC   364d            etcd-ca
# apiserver-kubelet-client   Nov 13, 2026 12:00 UTC   364d            ca
# controller-manager.conf    Nov 13, 2026 12:00 UTC   364d            ca
# etcd-healthcheck-client    Nov 13, 2026 12:00 UTC   364d            etcd-ca
# etcd-peer                  Nov 13, 2026 12:00 UTC   364d            etcd-ca
# etcd-server                Nov 13, 2026 12:00 UTC   364d            etcd-ca
# front-proxy-client         Nov 13, 2026 12:00 UTC   364d            front-proxy-ca
# scheduler.conf             Nov 13, 2026 12:00 UTC   364d            ca

# CERTIFICATE AUTHORITY      EXPIRES                  RESIDUAL TIME
# ca                         Nov 10, 2035 12:00 UTC   9y
# etcd-ca                    Nov 10, 2035 12:00 UTC   9y
# front-proxy-ca             Nov 10, 2035 12:00 UTC   9y

# Verificar certificado individual
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text | grep -A 2 Validity
```

### Renovar Certificados

#### Renovación Manual

```bash
# Renovar todos los certificados
sudo kubeadm certs renew all

# Renovar certificado específico
sudo kubeadm certs renew apiserver
sudo kubeadm certs renew apiserver-kubelet-client
sudo kubeadm certs renew front-proxy-client
sudo kubeadm certs renew etcd-server
sudo kubeadm certs renew etcd-peer

# Verificar renovación
sudo kubeadm certs check-expiration
```

#### Actualizar kubeconfig

Después de renovar certificados:

```bash
# Actualizar admin kubeconfig
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# O generar nuevo kubeconfig
sudo kubeadm init phase kubeconfig admin
```

#### Reiniciar Componentes

```bash
# Después de renovar certificados, reiniciar kubelet
sudo systemctl restart kubelet

# Para clusters con manifiestos estáticos, los pods se reiniciarán automáticamente
# Verificar
kubectl get pods -n kube-system -w
```

### Renovación Automática

Los certificados se renuevan automáticamente durante `kubeadm upgrade`:

```bash
# Durante upgrade, los certificados se renuevan si expiran en <180 días
sudo kubeadm upgrade apply v1.28.4

# Ver renovación en output:
# [upgrade] Backing up kubelet config
# [upgrade/certs] Renewing all certificates
# [upgrade/certs] Backing up certificates
```

### Rotación de Certificados de kubelet

```bash
# Habilitar rotación automática de certificados en kubelet
# Editar /var/lib/kubelet/config.yaml

# Agregar:
rotateCertificates: true
serverTLSBootstrap: true

# Reiniciar kubelet
sudo systemctl restart kubelet

# Verificar requests de certificados
kubectl get csr

# Aprobar CSRs
kubectl certificate approve <csr-name>

# O aprobar todos automáticamente (NO en producción sin review)
kubectl get csr -o name | xargs kubectl certificate approve
```

---

## 💾 Backup y Rollback

### Estrategia de Backup Pre-Upgrade

#### 1. Backup de etcd

```bash
# Backup completo de etcd
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-pre-upgrade-$(date +%Y%m%d-%H%M%S).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verificar snapshot
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-pre-upgrade-*.db --write-out=table
```

#### 2. Backup de Configuraciones

```bash
# Backup de /etc/kubernetes
sudo tar -czf /backup/kubernetes-configs-$(date +%Y%m%d).tar.gz /etc/kubernetes

# Backup de manifiestos
sudo tar -czf /backup/manifests-$(date +%Y%m%d).tar.gz /etc/kubernetes/manifests

# Backup de kubelet config
sudo cp /var/lib/kubelet/config.yaml /backup/kubelet-config-$(date +%Y%m%d).yaml
```

#### 3. Backup de Recursos

```bash
# Exportar todos los recursos
kubectl get all --all-namespaces -o yaml > /backup/all-resources-$(date +%Y%m%d).yaml

# Backup por namespace
for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}'); do
  kubectl get all -n $ns -o yaml > /backup/ns-${ns}-$(date +%Y%m%d).yaml
done

# Backup de CRDs
kubectl get crd -o yaml > /backup/crds-$(date +%Y%m%d).yaml
```

### Procedimiento de Rollback

Si el upgrade falla, hay varias opciones:

#### Opción 1: Rollback de Versión de Paquetes

```bash
# En cada nodo donde hiciste upgrade

# 1. Downgrade de paquetes (NO OFICIAL, usar con precaución)
sudo apt-mark unhold kubeadm kubelet kubectl
sudo apt-get install -y \
  kubeadm=1.27.8-00 \
  kubelet=1.27.8-00 \
  kubectl=1.27.8-00
sudo apt-mark hold kubeadm kubelet kubectl

# 2. Reiniciar kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# 3. Verificar
kubectl get nodes
```

⚠️ **ADVERTENCIA**: Downgrade NO es oficialmente soportado. Puede causar inconsistencias.

#### Opción 2: Restore de etcd (Preferido)

```bash
# Ver Lab 03 del Módulo 22 para procedimiento completo

# Resumen:
# 1. Detener kubelet
sudo systemctl stop kubelet

# 2. Mover etcd actual
sudo mv /var/lib/etcd /var/lib/etcd.failed-upgrade

# 3. Restaurar snapshot
sudo ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-pre-upgrade.db \
  --data-dir=/var/lib/etcd

# 4. Reiniciar kubelet
sudo systemctl start kubelet

# 5. Verificar
kubectl get nodes
kubectl get pods --all-namespaces
```

#### Opción 3: Recrear Cluster (Último Recurso)

Si todo falla:

1. Crear nuevo cluster con versión anterior
2. Restaurar etcd backup
3. Aplicar resource backups
4. Migrar workloads

---

## ✅ Best Practices

### Upgrade Strategy

1. **Siempre usar staging primero**
   ```bash
   # Test en staging cluster idéntico a producción
   # Mismo OS, misma configuración, mismo workload representativo
   ```

2. **Upgrades incrementales**
   ```bash
   # Correcto:
   1.27.0 → 1.27.8 (patches) → 1.28.0 → 1.28.4 (patches)
   
   # Incorrecto:
   1.27.0 → 1.29.0  # ❌ Saltó 1.28
   ```

3. **Maintenance windows**
   - Planificar con antelación
   - Comunicar a stakeholders
   - Tener plan de rollback
   - Documentar cada paso

4. **Monitoreo continuo**
   ```bash
   # Durante upgrade, monitorear:
   watch kubectl get nodes
   watch kubectl get pods --all-namespaces
   kubectl get events --sort-by='.lastTimestamp' -w
   ```

### Node Maintenance

1. **Usar PodDisruptionBudgets**
   - Proteger aplicaciones críticas
   - Evitar downtime durante drain

2. **Drain con precaución**
   ```bash
   # Siempre usar --ignore-daemonsets
   # Considerar --grace-period para apps con shutdown lento
   # Usar --timeout razonable
   ```

3. **Verificar antes de uncordon**
   ```bash
   # Asegurar que nodo está saludable
   kubectl get nodes
   ssh node 'sudo systemctl status kubelet containerd'
   ```

### Certificate Management

1. **Renovar antes de expiración**
   - Renovar cuando falten 90 días
   - No esperar al último minuto
   - Configurar alertas de expiración

2. **Backup de certs antes de renovar**
   ```bash
   sudo cp -r /etc/kubernetes/pki /backup/pki-$(date +%Y%m%d)
   ```

3. **Automatizar rotación de kubelet certs**
   ```yaml
   # En kubelet config
   rotateCertificates: true
   serverTLSBootstrap: true
   ```

### Backup Strategy

1. **Backups automáticos de etcd**
   ```bash
   # Cron job diario
   0 2 * * * /usr/local/bin/etcd-backup.sh backup
   ```

2. **Retention policy**
   - Daily backups: 7 días
   - Weekly backups: 4 semanas
   - Monthly backups: 12 meses

3. **Test de restores**
   - Probar restore mensualmente
   - Validar integridad de backups
   - Documentar procedimiento

---

## 🐛 Troubleshooting

### Upgrade Fallido

#### Problema: kubeadm upgrade apply falla

```bash
# Ver logs detallados
sudo kubeadm upgrade apply v1.28.4 -v=5

# Errores comunes:
# 1. etcd no saludable
sudo ETCDCTL_API=3 etcdctl endpoint health

# 2. API server no responde
kubectl get --raw /healthz

# 3. Certificados expirados
sudo kubeadm certs check-expiration

# 4. Espacio en disco insuficiente
df -h /var/lib/etcd
df -h /var/lib/kubelet
```

#### Problema: Pods no schedulan después de upgrade

```bash
# Verificar que workers no están cordoned
kubectl get nodes
# Si STATUS = SchedulingDisabled

# Uncordon
kubectl uncordon <node-name>

# Verificar taints
kubectl describe node <node-name> | grep Taint

# Ver events
kubectl get events --sort-by='.lastTimestamp' | grep -i schedule
```

### Drain Fallido

#### Problema: Drain se queda stuck

```bash
# Ver qué pods no pueden ser evacuados
kubectl get pods -o wide --all-namespaces | grep <node-name>

# Errores comunes:
# 1. PDB muy restrictivo
kubectl get pdb --all-namespaces
kubectl describe pdb <pdb-name>

# Solución temporal: Editar PDB
kubectl edit pdb <pdb-name>
# Reducir minAvailable o aumentar maxUnavailable

# 2. Pods sin controller (naked pods)
kubectl get pods --field-selector spec.nodeName=<node-name>

# Forzar eliminación
kubectl drain <node-name> --force

# 3. Pods con emptyDir
kubectl drain <node-name> --delete-emptydir-data
```

### Certificados

#### Problema: kubectl falla después de renovar certs

```bash
# Error:
# Unable to connect to the server: x509: certificate has expired

# Solución:
# 1. Actualizar kubeconfig
sudo cp /etc/kubernetes/admin.conf ~/.kube/config

# 2. O regenerar
sudo kubeadm init phase kubeconfig admin

# 3. Verificar
kubectl get nodes
```

#### Problema: kubelet no inicia después de cert renewal

```bash
# Ver logs
sudo journalctl -u kubelet -f

# Error común:
# certificate has expired or is not yet valid

# Solución:
# 1. Renovar certs de kubelet
sudo kubeadm certs renew apiserver-kubelet-client

# 2. Reiniciar kubelet
sudo systemctl restart kubelet

# 3. Verificar
sudo systemctl status kubelet
```

---

## 📚 Referencias

- [Upgrading kubeadm clusters](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)
- [Version Skew Policy](https://kubernetes.io/releases/version-skew-policy/)
- [Certificate Management](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)
- [Safely Drain Node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)
- [Kubernetes Release Notes](https://kubernetes.io/docs/setup/release/notes/)

---

## 🎯 Próximos Pasos

1. **Práctica**: Completar laboratorios de este módulo
2. **Documentación**: Crear runbooks de upgrade para tu organización
3. **Automatización**: Implementar scripts de upgrade
4. **Monitoreo**: Configurar alertas de expiración de certificados
5. **Avanzar**: Continuar con [Módulo 24: Advanced Scheduling](../modulo-24-advanced-scheduling/)

---

**Ver también:**
- [Laboratorios](./laboratorios/README.md) - Labs prácticos
- [Ejemplos](./ejemplos/README.md) - Scripts y configs
- [RESUMEN](./RESUMEN-MODULO.md) - Cheatsheet de comandos
