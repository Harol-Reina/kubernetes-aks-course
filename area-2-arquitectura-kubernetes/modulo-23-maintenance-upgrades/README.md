# Capítulo 25: Mantenimiento y Upgrades

En el capítulo anterior construimos el cluster desde cero con kubeadm: control plane inicializado, nodos unidos, red configurada. El cluster existe y funciona. Pero crear algo es solo el primer día; mantenerlo operativo durante años es el verdadero trabajo.

El problema es real y tiene consecuencias graves. Kubernetes publica una nueva minor version cada cuatro meses y solo soporta las tres últimas; quedarte en una versión fuera de soporte significa que las vulnerabilidades de seguridad que se descubran no recibirán parches. Más crítico aún: etcd es el único lugar donde vive todo el estado de tu cluster, todos los Pods, Deployments, Secrets, y configuraciones. Si etcd se corrompe o el disco falla sin un backup reciente, no puedes recuperar nada: el cluster es una pizarra en blanco y todo lo que corrías se ha perdido. Que esto ocurra en producción a las 3am es uno de los peores escenarios posibles en operaciones.

La solución es una práctica sistemática de mantenimiento: backups periódicos de etcd que se puedan restaurar en minutos, upgrades planificados un minor version a la vez siguiendo el orden correcto (control plane primero, workers después), y el uso de `drain` y `cordon` para sacar nodos del servicio de forma segura antes de cualquier operación de mantenimiento.

Piénsalo como el mantenimiento de un coche: los backups de etcd son como cambiar el aceite regularmente (previenen daños mayores), los upgrades de versión son como reemplazar piezas del motor mientras el coche sigue en marcha (hay que hacerlo con cuidado y en el orden correcto), y el drain de nodos es como sacar el coche del carril de alta velocidad antes de abrirle el capó.

En este capítulo aprenderás a hacer snapshots de etcd y restaurarlos ante un desastre, a planificar y ejecutar upgrades con kubeadm paso a paso, a usar `kubectl drain` y `kubectl cordon` para mantenimiento seguro de nodos, y a definir ventanas de mantenimiento que minimicen el impacto en los usuarios.

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

## ⚠️ Escenarios de Fallo Durante Upgrades

Los upgrades pueden fallar de formas predecibles. Conocer estos escenarios de antemano permite responder con rapidez y sin improvisación.

### Escenario 1: Control Plane Actualizado, Workers Incompatibles

**Sintoma:** `kubectl get nodes` muestra workers en `NotReady` o con versiones incompatibles tras actualizar el control plane.

**Causa:** El skew de versiones supera el limite permitido. Si el control plane está en 1.29 y los workers siguen en 1.27, el kubelet de los workers queda fuera de la ventana N-2.

```
Control Plane: 1.29
├── kubelet: 1.28-1.29 ✅ (N-1, dentro del skew permitido)
├── kubelet: 1.27     ❌ (N-2, NO soportado)
└── kubectl: 1.28-1.30 ✅ (N-1 a N+1, permitido)
```

**Solucion:**

```bash
# Verificar versiones de todos los nodos
kubectl get nodes -o custom-columns='NAME:.metadata.name,VERSION:.status.nodeInfo.kubeletVersion'
# NAME          VERSION
# master-01     v1.29.0
# worker-01     v1.27.8   <- problema: demasiado atras

# Actualizar workers inmediatamente (seguir proceso de upgrade in-place)
kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data
# Upgrade de kubelet en el worker...
kubectl uncordon worker-01
```

**Prevencion:** Nunca dejar pasar mas de una minor version de diferencia entre control plane y workers. Planificar el upgrade de workers en la misma ventana de mantenimiento que el control plane.

### Escenario 2: Corrupcion de etcd Durante el Upgrade

**Sintoma:** El API server no responde, los pods no se schedulan, `etcdctl endpoint health` devuelve errores.

**Causa:** Fallo de disco, reinicio abrupto del nodo de etcd durante la escritura, o fallo de red en configuracion etcd externo.

**Por que ocurre:** etcd usa un algoritmo de consenso (Raft) que requiere quorum. Si un nodo de etcd falla durante un upgrade y el cluster pierde quorum, el cluster entero se detiene.

**Solucion: siempre tener un snapshot ANTES del upgrade.**

```bash
# Verificar salud de etcd antes de cualquier upgrade
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
# Output esperado:
# https://127.0.0.1:2379 is healthy: successfully committed proposal: took = 1.2ms

# Tomar snapshot ANTES del upgrade
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-pre-upgrade-$(date +%Y%m%d-%H%M).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

Si etcd se corrompe y hay un snapshot, consultar la seccion "Procedimientos de Rollback Detallados" mas abajo.

### Escenario 3: CRDs Incompatibles con la Nueva Version

**Sintoma:** Tras el upgrade, recursos custom (como los de Prometheus Operator, cert-manager o Istio) dejan de funcionar. Los pods del operator crashean con errores de API no encontrada.

**Causa:** Las APIs de Kubernetes se deprecan y eliminan entre versiones. Ejemplo historico: `extensions/v1beta1` fue eliminado en 1.22, `batch/v1beta1` en 1.25.

```bash
# Verificar que APIs deprecadas siguen en uso en tu cluster
# Requiere el plugin kubectl-convert o kubectl deprecations
kubectl api-resources | grep -i "extensions"

# Ver que versiones de API soporta el cluster nuevo
kubectl api-versions | sort

# Buscar recursos que usan APIs deprecadas
kubectl get <recurso> -o yaml | grep apiVersion
```

**Solucion:**

```bash
# 1. Revisar release notes de la version objetivo antes del upgrade
# https://kubernetes.io/docs/reference/using-api/deprecation-guide/

# 2. Convertir manifiestos a la nueva API con kubectl-convert
kubectl convert -f deployment-viejo.yaml --output-version apps/v1

# 3. Actualizar los operadores (Helm charts, etc.) ANTES del upgrade del cluster
helm upgrade prometheus-stack prometheus-community/kube-prometheus-stack

# 4. Verificar compatibilidad de addons en el changelog del addon
```

**Prevencion:** Probar en un cluster de staging con la misma version objetivo ANTES de tocar produccion. Revisar siempre el migration guide de la version.

### Escenario 4: Aplicacion Rompe Despues del Upgrade

**Sintoma:** Las aplicaciones propias dejan de arrancar con errores como `no matches for kind "Deployment" in version "extensions/v1beta1"`.

**Causa:** Los manifiestos YAML de la aplicacion referencian APIs que fueron eliminadas en la nueva version de Kubernetes.

```bash
# Detectar uso de APIs eliminadas en tus propios manifiestos
grep -r "apiVersion: extensions" ./manifests/
grep -r "apiVersion: batch/v1beta1" ./manifests/

# Verificar con el plugin kubectl-deprecations (si esta instalado)
kubectl deprecations --filename ./manifests/

# Ver que cambios de API aplican a la version objetivo
# Consultar: https://kubernetes.io/docs/reference/using-api/deprecation-guide/
```

**Solucion:** Actualizar los manifiestos a las APIs estables antes del upgrade del cluster. Los cambios mas comunes:

```
extensions/v1beta1 Deployment  →  apps/v1 Deployment
extensions/v1beta1 Ingress     →  networking.k8s.io/v1 Ingress
batch/v1beta1 CronJob          →  batch/v1 CronJob
policy/v1beta1 PodDisruptionBudget  →  policy/v1 PodDisruptionBudget
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

## 🔁 Procedimientos de Rollback Detallados

El rollback de un upgrade de Kubernetes es una operacion delicada. kubeadm no soporta oficialmente el downgrade de versiones, por lo que el metodo preferido siempre es restaurar desde un snapshot de etcd. Esta seccion detalla ambas opciones.

### Rollback Via Restauracion de etcd (Metodo Preferido)

Este metodo revierte el estado completo del cluster al momento en que se tomo el snapshot. Es la unica forma de rollback que Kubernetes considera segura y es la que se pide en el examen CKA.

```bash
# Paso 1: Identificar las versiones actual y anterior
kubeadm version
# kubeadm version: &Version{Major:1,Minor:28,...}

kubectl version --short
# Client Version: v1.28.4
# Server Version: v1.28.4

# Paso 2: Detener el kube-apiserver para evitar escrituras durante el restore
# Los manifiestos estaticos se mueven fuera del directorio watched
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kube-apiserver.yaml

# Verificar que el pod de kube-apiserver ha desaparecido
sudo crictl pods | grep apiserver
# (no output esperado — el pod debe haber terminado)

# Paso 3: Restaurar el snapshot de etcd al directorio de datos
# IMPORTANTE: el directorio destino NO debe existir previamente
sudo ETCDCTL_API=3 etcdctl snapshot restore \
  /backup/etcd-pre-upgrade.db \
  --data-dir=/var/lib/etcd-restored \
  --name=master-01 \
  --initial-cluster=master-01=https://127.0.0.1:2380 \
  --initial-cluster-token=etcd-cluster-1 \
  --initial-advertise-peer-urls=https://127.0.0.1:2380

# Paso 4: Reemplazar el directorio de datos de etcd
sudo mv /var/lib/etcd /var/lib/etcd.failed-upgrade
sudo mv /var/lib/etcd-restored /var/lib/etcd

# Paso 5: Apuntar el manifiesto de etcd al directorio restaurado
# Editar /etc/kubernetes/manifests/etcd.yaml si usa ruta diferente
# Verificar que el hostPath sea /var/lib/etcd
sudo grep -A 2 "hostPath" /etc/kubernetes/manifests/etcd.yaml

# Paso 6: Restaurar el kube-apiserver
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml

# Paso 7: Esperar a que el control plane se recupere (puede tardar 1-3 minutos)
kubectl get nodes
# NAME        STATUS   ROLES           AGE   VERSION
# master-01   Ready    control-plane   30d   v1.27.8   <- version del snapshot

# Paso 8: Verificar que el estado del cluster es consistente con el backup
kubectl get pods --all-namespaces
kubectl get deployments --all-namespaces
```

### Rollback Via Downgrade de Paquetes (No Oficial)

Este metodo intenta instalar versiones anteriores de los paquetes kubeadm, kubelet y kubectl. Solo funciona para rollback de patch versions y no garantiza consistencia con el estado de etcd.

```bash
# ADVERTENCIA: Este metodo NO es soportado oficialmente por Kubernetes.
# Solo usar como ultimo recurso para rollback de patch versions (1.28.4 -> 1.28.2).
# Para minor versions, usar siempre el metodo de restore de etcd.

# Paso 1: Desbloquear paquetes
sudo apt-mark unhold kubeadm kubelet kubectl

# Paso 2: Instalar version anterior
sudo apt-get install -y \
  kubeadm=1.27.8-00 \
  kubelet=1.27.8-00 \
  kubectl=1.27.8-00

# Paso 3: Bloquear paquetes en version anterior
sudo apt-mark hold kubeadm kubelet kubectl

# Paso 4: Reiniciar kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Paso 5: Verificar
kubectl get nodes
```

### Checklist de Rollback

Antes de ejecutar cualquier rollback, verificar:

- [ ] El snapshot de etcd existe y fue tomado ANTES del upgrade problemático
- [ ] El snapshot corresponde a la version de Kubernetes correcta
- [ ] El equipo ha sido notificado de la ventana de rollback
- [ ] El problema que causó el rollback está documentado con evidencia (logs, screenshots)
- [ ] Se ha probado el procedimiento en staging previamente
- [ ] El runbook de rollback está disponible y actualizado
- [ ] Hay un responsable de comunicaciones hacia los usuarios durante el rollback

### Medidas Preventivas Para Evitar Rollbacks

La mejor forma de gestionar un rollback es no necesitarlo. Estas practicas reducen la probabilidad de que un upgrade requiera rollback:

1. **Snapshot obligatorio antes de cualquier operacion de cluster**
   ```bash
   # Este comando debe ejecutarse como primer paso de CUALQUIER upgrade
   ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-$(date +%Y%m%d-%H%M).db \
     --endpoints=https://127.0.0.1:2379 \
     --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     --cert=/etc/kubernetes/pki/etcd/server.crt \
     --key=/etc/kubernetes/pki/etcd/server.key
   ```

2. **Mantener paquetes de la version anterior disponibles**
   ```bash
   # Guardar los paquetes descargados antes de hacer unhold
   sudo apt-cache show kubeadm | grep Version
   # Descargar sin instalar para tener el .deb de la version N-1
   sudo apt-get download kubeadm=1.27.8-00 kubelet=1.27.8-00 kubectl=1.27.8-00
   ```

3. **Probar el upgrade completo en staging** con el mismo workload representativo de produccion antes de la ventana de mantenimiento.

4. **Definir un criterio de rollback** antes de empezar: si en X minutos después de aplicar el upgrade no se cumple la condicion Y, se inicia rollback automaticamente.

5. **Documentar un runbook de rollback** que cualquier miembro del equipo pueda ejecutar sin depender de quien hizo el upgrade.

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

## Resumen del Capítulo

Este capítulo cubrió el mantenimiento de clusters Kubernetes: estrategias de upgrade, version skew policy, actualización del control plane y workers con kubeadm, drenado de nodos, gestión de certificados, backup y restore de etcd, y procedimientos de rollback.
