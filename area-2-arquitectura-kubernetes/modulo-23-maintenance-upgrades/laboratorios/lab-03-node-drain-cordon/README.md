# Lab 03: Node Drain, Cordon & Maintenance

**Duracion estimada:** 30-45 minutos
**Nivel:** Intermedio
**Objetivo:** Dominar operaciones de mantenimiento de nodos (drain, cordon, uncordon) y PodDisruptionBudgets

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **kubectl cordon** | Marcar un nodo como SchedulingDisabled para prevenir nuevos pods |
| **kubectl drain** | Evacuar pods de un nodo de forma segura respetando PDBs |
| **kubectl uncordon** | Restaurar scheduling en un nodo despues de mantenimiento |
| **PodDisruptionBudget** | Definir minimo de replicas disponibles durante disrupciones voluntarias |
| **DaemonSet behavior** | Entender por que los DaemonSets permanecen durante drain |
| **Graceful shutdown** | Proceso SIGTERM + terminationGracePeriodSeconds durante evacuacion |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las operaciones se realizan mediante archivos YAML:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `nginx-demo-deployment.yaml` | 1 | Deployment con 6 replicas para demostrar distribucion y migracion de pods |
| `critical-app-deployment-pdb.yaml` | 2 | Deployment critico (4 replicas) + PDB con minAvailable: 2 |
| `node-monitor-daemonset.yaml` | 3 | DaemonSet de monitoreo que permanece durante drain |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `drain-demo.sh` | Demo interactiva guiada de drain con 8 pasos |
| `verify-drain.sh` | Script de verificacion del estado del lab (nodos, PDBs, pods) |
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |

---

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio, seras capaz de:

- Realizar mantenimiento de nodos sin causar downtime de aplicaciones
- Usar `kubectl drain` para evacuar pods de forma segura
- Entender la diferencia entre `drain`, `cordon` y `uncordon`
- Manejar PodDisruptionBudgets (PDBs) durante mantenimiento
- Trabajar con node taints y tolerations
- Implementar graceful shutdown de aplicaciones

---

## Prerequisitos

Antes de comenzar, asegúrate de:

1. ✅ Tener un cluster Kubernetes con **al menos 2 worker nodes**
2. ✅ Deployments con múltiples réplicas corriendo
3. ✅ Permisos para drenar nodos (`kubectl drain`)
4. ✅ Acceso SSH a los nodos (para simular mantenimiento)

**Verifica prerequisitos:**
```bash
# Verificar número de nodos
kubectl get nodes

# Debe mostrar al menos 2 workers
# NAME                STATUS   ROLES           AGE   VERSION
# k8s-control-plane   Ready    control-plane   30d   v1.28.0
# k8s-worker-01       Ready    <none>          30d   v1.28.0
# k8s-worker-02       Ready    <none>          30d   v1.28.0

# Verificar que hay deployments corriendo
kubectl get deployments -A
```

📖 **Ver detalles completos**: [SETUP.md](./SETUP.md)

---

## 🏗️ Arquitectura del Mantenimiento de Nodos

```
ESTADO INICIAL - Cluster con 2 Workers
┌─────────────────────────────────────────────────────────────┐
│                    CONTROL PLANE                            │
│                  kube-apiserver                             │
└─────────────────────────────────────────────────────────────┘
              │                           │
    ┌─────────┴─────────┐       ┌────────┴─────────┐
    │   WORKER-01       │       │   WORKER-02      │
    │   Status: Ready   │       │   Status: Ready  │
    │                   │       │                  │
    │   Pod A (rep 1/3) │       │   Pod A (rep 2/3)│
    │   Pod B (rep 1/2) │       │   Pod A (rep 3/3)│
    │   Pod C           │       │   Pod B (rep 2/2)│
    └───────────────────┘       └──────────────────┘

FASE 1: CORDON - Marcar nodo para mantenimiento
┌─────────────────────────────────────────────────────────────┐
│ kubectl cordon worker-01                                    │
└─────────────────────────────────────────────────────────────┘
    ┌─────────────────────┐       ┌──────────────────┐
    │   WORKER-01         │       │   WORKER-02      │
    │ ⚠️ SchedulingDisabled│       │   Status: Ready  │
    │                     │       │                  │
    │   Pod A (rep 1/3)   │       │   Pod A (rep 2/3)│
    │   Pod B (rep 1/2)   │       │   Pod A (rep 3/3)│
    │   Pod C             │       │   Pod B (rep 2/2)│
    └─────────────────────┘       └──────────────────┘
    Nuevos pods NO se      ←       Nuevos pods VAN aquí
    crearán aquí

FASE 2: DRAIN - Evacuar pods existentes
┌─────────────────────────────────────────────────────────────┐
│ kubectl drain worker-01 --ignore-daemonsets                 │
│ --delete-emptydir-data                                      │
└─────────────────────────────────────────────────────────────┘
    ┌─────────────────────┐       ┌──────────────────┐
    │   WORKER-01         │       │   WORKER-02      │
    │ ⚠️ SchedulingDisabled│       │   Status: Ready  │
    │                     │       │                  │
    │   (vacío)           │  ───→ │   Pod A (rep 1/3)│
    │   Solo DaemonSets   │  ───→ │   Pod A (rep 2/3)│
    │                     │  ───→ │   Pod A (rep 3/3)│
    └─────────────────────┘       │   Pod B (rep 1/2)│
    Listo para                    │   Pod B (rep 2/2)│
    mantenimiento                 │   Pod C          │
                                  └──────────────────┘

FASE 3: MANTENIMIENTO - Realizar cambios en el nodo
┌─────────────────────────────────────────────────────────────┐
│ # SSH al nodo                                               │
│ ssh worker-01                                               │
│                                                             │
│ # Actualizar paquetes, reiniciar, etc.                     │
│ sudo apt-get update && sudo apt-get upgrade                │
│ sudo reboot                                                 │
└─────────────────────────────────────────────────────────────┘

FASE 4: UNCORDON - Habilitar scheduling nuevamente
┌─────────────────────────────────────────────────────────────┐
│ kubectl uncordon worker-01                                  │
└─────────────────────────────────────────────────────────────┘
    ┌─────────────────────┐       ┌──────────────────┐
    │   WORKER-01         │       │   WORKER-02      │
    │   Status: Ready ✓   │       │   Status: Ready  │
    │                     │       │                  │
    │   (vacío)           │       │   Pod A (rep 1/3)│
    │   Listo para recibir│       │   Pod A (rep 2/3)│
    │   nuevos pods       │       │   Pod A (rep 3/3)│
    └─────────────────────┘       │   Pod B (rep 1/2)│
                                  │   Pod B (rep 2/2)│
                                  │   Pod C          │
                                  └──────────────────┘

RESULTADO FINAL - Balance natural
┌─────────────────────────────────────────────────────────────┐
│ Los nuevos pods se distribuirán entre ambos nodos          │
└─────────────────────────────────────────────────────────────┘
    ┌─────────────────────┐       ┌──────────────────┐
    │   WORKER-01         │       │   WORKER-02      │
    │   Status: Ready     │       │   Status: Ready  │
    │                     │       │                  │
    │   Pod X (nuevo)     │       │   Pod A (rep 1/3)│
    │   Pod Y (nuevo)     │       │   Pod A (rep 2/3)│
    │                     │       │   Pod A (rep 3/3)│
    └─────────────────────┘       └──────────────────┘
```

---

## 📚 Conceptos Clave

### Comandos de Mantenimiento de Nodos

| Comando | Efecto en Pods Existentes | Nuevos Pods | Uso |
|---------|---------------------------|-------------|-----|
| **`kubectl cordon <node>`** | ❌ NO los afecta | 🚫 NO se programan | Prevenir scheduling |
| **`kubectl drain <node>`** | ✅ Los evacua (delete) | 🚫 NO se programan | Mantenimiento completo |
| **`kubectl uncordon <node>`** | ❌ NO los afecta | ✅ Vuelven a programarse | Restaurar scheduling |

### Drain vs Cordon

**`kubectl cordon`**:
- Marca el nodo como `SchedulingDisabled`
- Los pods existentes **NO se mueven**
- Solo previene nuevos pods
- Útil para: Preparar mantenimiento gradual

**`kubectl drain`**:
- Hace `cordon` automáticamente
- **Evacua** todos los pods (excepto DaemonSets)
- Respeta `PodDisruptionBudgets`
- Espera graceful termination
- Útil para: Mantenimiento inmediato, upgrades

### PodDisruptionBudgets (PDB)

Un **PodDisruptionBudget** limita cuántos pods pueden estar down simultáneamente:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: my-app-pdb
spec:
  minAvailable: 2  # Mínimo 2 pods siempre disponibles
  selector:
    matchLabels:
      app: my-app
```

**Comportamiento durante drain**:
- `kubectl drain` **espera** hasta que el PDB lo permita
- Si `minAvailable` no se puede cumplir, drain se bloquea
- Flags para override: `--disable-eviction` o `--force`

---

## 🛠️ Procedimiento del Laboratorio

### Parte 1: Setup - Crear Aplicaciones de Prueba

#### Paso 1.1: Deployment con múltiples réplicas

```bash
# Crear namespace de prueba
kubectl create namespace drain-test

# Deployment con 6 replicas (distribuidas entre workers)
kubectl apply -f nginx-demo-deployment.yaml
```

**Verificar distribución:**
```bash
kubectl get pods -n drain-test -o wide

# Deberías ver pods distribuidos entre worker-01 y worker-02
```

#### Paso 1.2: Deployment con PodDisruptionBudget

```bash
# Deployment critico con PDB (minAvailable: 2)
kubectl apply -f critical-app-deployment-pdb.yaml
```

**Verificar PDB:**
```bash
kubectl get pdb -n drain-test

# Output esperado:
# NAME               MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
# critical-app-pdb   2               N/A               2                     10s
```

#### Paso 1.3: DaemonSet (no se evacua con drain)

```bash
# DaemonSet de ejemplo (simula node monitoring)
kubectl apply -f node-monitor-daemonset.yaml
```

**Verificar que hay 1 pod por nodo:**
```bash
kubectl get pods -n drain-test -l app=node-monitor -o wide
```

---

### Parte 2: Cordon - Prevenir Nuevos Pods

#### Paso 2.1: Identificar nodo para mantenimiento

```bash
# Listar nodos y su carga
kubectl get nodes -o wide

# Ver pods en cada nodo
kubectl get pods -A -o wide --field-selector spec.nodeName=k8s-worker-01
```

Elige el nodo con **menos pods críticos** para este ejercicio.

#### Paso 2.2: Cordon del nodo

```bash
# Marcar worker-01 para mantenimiento
kubectl cordon k8s-worker-01

# Verificar estado
kubectl get nodes

# Output esperado:
# NAME                STATUS                     ROLES           AGE   VERSION
# k8s-control-plane   Ready                      control-plane   30d   v1.28.0
# k8s-worker-01       Ready,SchedulingDisabled   <none>          30d   v1.28.0  ← Cordoned
# k8s-worker-02       Ready                      <none>          30d   v1.28.0
```

#### Paso 2.3: Verificar comportamiento de nuevos pods

```bash
# Escalar deployment para crear nuevos pods
kubectl scale deployment nginx-demo -n drain-test --replicas=10

# Ver dónde se programan los nuevos pods
kubectl get pods -n drain-test -o wide

# Los nuevos 4 pods SOLO irán a worker-02 (no a worker-01 cordoned)
```

**✅ Verificación:**
- Los pods existentes en `worker-01` **siguen corriendo**
- Los nuevos pods **solo van a `worker-02`**

---

### Parte 3: Drain - Evacuar Pods

#### Paso 3.1: Intentar drain básico

```bash
# Primer intento de drain (fallará por DaemonSets)
kubectl drain k8s-worker-01

# Error esperado:
# error: cannot delete DaemonSet-managed Pods (use --ignore-daemonsets to ignore)
# ...
```

#### Paso 3.2: Drain correcto con flags

```bash
# Drain ignorando DaemonSets
kubectl drain k8s-worker-01 --ignore-daemonsets --delete-emptydir-data

# Output esperado:
# node/k8s-worker-01 already cordoned
# WARNING: ignoring DaemonSet-managed Pods: drain-test/node-monitor-xxxxx
# evicting pod drain-test/nginx-demo-xxxxx
# evicting pod drain-test/critical-app-xxxxx
# ...
# pod/nginx-demo-xxxxx evicted
# pod/critical-app-xxxxx evicted
# node/k8s-worker-01 drained
```

**Proceso durante drain:**
1. Pods reciben `SIGTERM` (graceful shutdown)
2. Esperan `terminationGracePeriodSeconds` (default 30s)
3. Deployment controller crea réplicas en otros nodos
4. Pods originales terminan

#### Paso 3.3: Verificar evacuación

```bash
# Ver pods en worker-01 (solo DaemonSets deben quedar)
kubectl get pods -A -o wide --field-selector spec.nodeName=k8s-worker-01

# Output esperado: Solo DaemonSets
# NAMESPACE    NAME                  READY   STATUS    RESTARTS   AGE
# drain-test   node-monitor-xxxxx    1/1     Running   0          5m
# kube-system  kube-proxy-xxxxx      1/1     Running   0          30d

# Ver que los pods migraron a worker-02
kubectl get pods -n drain-test -o wide | grep -v monitor
```

---

### Parte 4: Mantenimiento del Nodo

Ahora que el nodo está drenado, puedes realizar mantenimiento:

#### Paso 4.1: Simular mantenimiento

```bash
# Opción 1: Actualización de paquetes (sin reiniciar)
ssh k8s-worker-01 "sudo apt-get update && sudo apt-get upgrade -y"

# Opción 2: Reinicio completo
ssh k8s-worker-01 "sudo reboot"

# Esperar a que el nodo vuelva
kubectl get nodes -w
```

#### Paso 4.2: Verificar que el nodo volvió

```bash
# Después del reinicio
kubectl get nodes

# El nodo estará Ready, pero SIGUE CORDONED:
# k8s-worker-01   Ready,SchedulingDisabled   <none>   30d   v1.28.0
```

⚠️ **IMPORTANTE**: `drain` deja el nodo en estado `SchedulingDisabled`. Debes hacer `uncordon` manualmente.

---

### Parte 5: Uncordon - Restaurar Scheduling

#### Paso 5.1: Habilitar scheduling

```bash
# Uncordon del nodo
kubectl uncordon k8s-worker-01

# Verificar estado
kubectl get nodes

# Output esperado:
# NAME                STATUS   ROLES           AGE   VERSION
# k8s-control-plane   Ready    control-plane   30d   v1.28.0
# k8s-worker-01       Ready    <none>          30d   v1.28.0  ← Ya no tiene SchedulingDisabled
# k8s-worker-02       Ready    <none>          30d   v1.28.0
```

#### Paso 5.2: Verificar rebalanceo gradual

```bash
# Los pods NO se mueven automáticamente después de uncordon
kubectl get pods -n drain-test -o wide

# Siguen en worker-02

# Pero los NUEVOS pods se distribuirán
kubectl scale deployment nginx-demo -n drain-test --replicas=12

# Ver distribución de los nuevos pods
kubectl get pods -n drain-test -o wide

# Ahora verás pods en ambos workers
```

---

### Parte 6: Forzar Rebalanceo (Opcional)

Si quieres forzar redistribución de pods existentes:

#### Opción 1: Restart del Deployment

```bash
kubectl rollout restart deployment nginx-demo -n drain-test

# Esperar a que termine
kubectl rollout status deployment nginx-demo -n drain-test

# Ver distribución balanceada
kubectl get pods -n drain-test -o wide
```

#### Opción 2: Drenar el otro nodo (rolling)

```bash
# Ahora drena worker-02
kubectl drain k8s-worker-02 --ignore-daemonsets --delete-emptydir-data

# Los pods migrarán a worker-01 (ya uncordoned)

# Luego uncordon worker-02
kubectl uncordon k8s-worker-02
```

---

## 🧪 Validación del Laboratorio

### Checklist de Completitud

- [ ] **Cordon ejecutado** correctamente en un nodo
- [ ] **Nuevos pods** NO se programan en nodo cordoned
- [ ] **Drain ejecutado** con flags apropiados
- [ ] **DaemonSets** permanecen en el nodo drenado
- [ ] **Pods evacuados** correctamente a otros nodos
- [ ] **PodDisruptionBudget** respetado durante drain
- [ ] **Mantenimiento** simulado (actualización o reinicio)
- [ ] **Uncordon ejecutado** después de mantenimiento
- [ ] **Nuevos pods** se pueden programar en nodo uncordoned
- [ ] **Cleanup** completado

### Script de Verificación

```bash
./verify-drain.sh
```

El script verificará:
- ✅ Estados de nodos (Ready vs SchedulingDisabled)
- ✅ Distribución de pods entre nodos
- ✅ PodDisruptionBudgets activos
- ✅ DaemonSets en todos los nodos

---

## 🔍 Troubleshooting

### Problema 1: Drain se bloquea indefinidamente

**Síntomas:**
```bash
kubectl drain worker-01 --ignore-daemonsets
evicting pod default/my-pod
error when evicting pod "my-pod": Cannot evict pod as it would violate the pod's disruption budget.
```

**Causa**: PodDisruptionBudget impide la evacuación

**Soluciones:**

**Opción 1: Esperar** (recomendado)
```bash
# El drain eventualmente procederá cuando el PDB lo permita
# Esto puede tomar tiempo si otros pods también están down
```

**Opción 2: Verificar PDB**
```bash
kubectl get pdb -A

# Ver detalles del PDB problemático
kubectl describe pdb <pdb-name> -n <namespace>

# Ver cuántos pods están disponibles
# ALLOWED DISRUPTIONS debe ser > 0 para que drain funcione
```

**Opción 3: Temporalmente modificar PDB** (CUIDADO)
```bash
# Reducir minAvailable
kubectl edit pdb <pdb-name> -n <namespace>

# Cambiar:
# minAvailable: 3
# a:
# minAvailable: 1

# Después del drain, restaurar el valor original
```

**Opción 4: Forzar drain** (ÚLTIMO RECURSO)
```bash
# Ignora PDBs - PUEDE CAUSAR DOWNTIME
kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data --force --disable-eviction

# ⚠️ Usa solo en emergencias
```

---

### Problema 2: Pods con emptyDir no se evacuan

**Síntomas:**
```bash
error: cannot delete Pods with local storage (use --delete-emptydir-data to override)
```

**Causa**: Pods usando volúmenes `emptyDir`

**Solución:**
```bash
# Agregar flag --delete-emptydir-data
kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data

# ⚠️ Esto ELIMINARÁ los datos en emptyDir (temporal por diseño)
```

**Prevención**:
- Usa `PersistentVolumes` para datos importantes
- `emptyDir` es para datos temporales/cache

---

### Problema 3: Pods "standalone" no se pueden drenar

**Síntomas:**
```bash
error: cannot delete Pods not managed by ReplicationController, ReplicaSet, Job, DaemonSet or StatefulSet
```

**Causa**: Pod creado directamente (no por controller)

**Identificar:**
```bash
kubectl get pods -A -o json | jq '.items[] | select(.metadata.ownerReferences == null) | .metadata.name'
```

**Solución:**
```bash
# Opción 1: Eliminar el pod manualmente primero
kubectl delete pod <pod-name> -n <namespace>

# Luego drain
kubectl drain worker-01 --ignore-daemonsets

# Opción 2: Forzar con --force
kubectl drain worker-01 --ignore-daemonsets --force

# ⚠️ El pod se eliminará y NO se recreará (no hay controller)
```

---

### Problema 4: Drain tarda demasiado

**Síntomas:**
```bash
# Drain se queda en "evicting pod..." por minutos
```

**Causas posibles:**
1. `terminationGracePeriodSeconds` muy alto
2. Pod con finalizers
3. Pod con hooks de pre-stop lentos

**Diagnóstico:**
```bash
# Ver grace period del pod
kubectl get pod <pod-name> -o yaml | grep terminationGracePeriodSeconds

# Ver events
kubectl get events --sort-by='.lastTimestamp' | grep <pod-name>
```

**Solución:**
```bash
# Reducir grace period temporalmente
kubectl drain worker-01 --ignore-daemonsets --grace-period=30

# Si sigue bloqueado, forzar:
kubectl drain worker-01 --ignore-daemonsets --grace-period=0 --force
```

---

### Problema 5: Nodo no vuelve a Ready después de reinicio

**Síntomas:**
```bash
kubectl get nodes
NAME          STATUS      ROLES    AGE   VERSION
worker-01     NotReady    <none>   30d   v1.28.0
```

**Diagnóstico:**
```bash
# SSH al nodo
ssh worker-01

# Verificar kubelet
sudo systemctl status kubelet

# Ver logs
sudo journalctl -xeu kubelet | tail -50
```

**Soluciones comunes:**
```bash
# 1. Reiniciar kubelet
sudo systemctl restart kubelet

# 2. Verificar container runtime
sudo systemctl status containerd
sudo systemctl restart containerd
sudo systemctl restart kubelet

# 3. Verificar CNI
ls /etc/cni/net.d/
```

---

## 📚 Comandos de Referencia Rápida

### Comandos Esenciales CKA

```bash
# CORDON - Prevenir scheduling
kubectl cordon <node>

# UNCORDON - Habilitar scheduling
kubectl uncordon <node>

# DRAIN - Evacuar pods (flags más comunes)
kubectl drain <node> \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --grace-period=30

# DRAIN FORZADO (emergencias)
kubectl drain <node> \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --force \
  --grace-period=0

# Ver estado de nodos
kubectl get nodes

# Ver pods en un nodo específico
kubectl get pods -A -o wide --field-selector spec.nodeName=<node>

# Ver PodDisruptionBudgets
kubectl get pdb -A

# Ver detalles de PDB
kubectl describe pdb <pdb-name> -n <namespace>
```

### Workflow Completo de Mantenimiento

```bash
# 1. Preparación
kubectl get nodes                           # Ver nodos disponibles
kubectl get pods -A -o wide                 # Ver distribución de pods

# 2. Cordon
kubectl cordon worker-01                    # Prevenir nuevos pods

# 3. Verificar
kubectl get nodes                           # Confirmar SchedulingDisabled

# 4. Drain
kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data

# 5. Mantenimiento
ssh worker-01 "sudo apt-get upgrade -y"    # O cualquier mantenimiento
ssh worker-01 "sudo reboot"                 # Si es necesario

# 6. Verificar nodo volvió
kubectl get nodes -w                        # Esperar Ready

# 7. Uncordon
kubectl uncordon worker-01                  # Restaurar scheduling

# 8. Verificar
kubectl get nodes                           # Confirmar Ready (sin SchedulingDisabled)
```

---

## 🎓 Conceptos para el Examen CKA

### Puntos Críticos para Memorizar

1. **Drain vs Cordon**:
   - `cordon`: Solo previene nuevos pods
   - `drain`: Cordon + evacua pods existentes

2. **Flags comunes de drain**:
   ```bash
   --ignore-daemonsets      # Siempre necesario (DaemonSets no se evacuan)
   --delete-emptydir-data   # Para pods con emptyDir
   --force                  # Para pods standalone (sin controller)
   --grace-period=<seconds> # Tiempo de shutdown graceful
   ```

3. **DaemonSets**:
   - NUNCA se evacuan con drain
   - Permanecen en el nodo (por diseño)
   - Usa `--ignore-daemonsets` siempre

4. **PodDisruptionBudgets**:
   - Drain **respeta** PDBs por defecto
   - Puede bloquear drain si `minAvailable` no se cumple
   - Override con `--disable-eviction` (CUIDADO)

5. **Uncordon NO es automático**:
   - Después de drain/reinicio, nodo sigue `SchedulingDisabled`
   - Debes hacer `uncordon` manualmente

### Escenario Típico de Examen

**Tarea:**
> "Perform maintenance on worker-01. Drain all pods safely, then uncordon the node."

**Solución (5 minutos):**

```bash
# 1. Verificar estado inicial
kubectl get nodes

# 2. Cordon opcional (drain lo hace automáticamente)
kubectl cordon worker-01

# 3. Drain
kubectl drain worker-01 --ignore-daemonsets --delete-emptydir-data

# 4. Verificar evacuación
kubectl get pods -A -o wide | grep worker-01
# (Solo DaemonSets deben aparecer)

# 5. Simular mantenimiento (si se pide)
# ssh worker-01 "sudo reboot"

# 6. Uncordon
kubectl uncordon worker-01

# 7. Verificar
kubectl get nodes
# worker-01 debe estar Ready (sin SchedulingDisabled)
```

**Tiempo estimado en examen**: 3-5 minutos

---

## 🧹 Limpieza del Laboratorio

```bash
# Ejecutar script de limpieza
./cleanup.sh
```

El script realizará:
- ✅ Uncordon de todos los nodos
- ✅ Eliminación del namespace `drain-test`
- ✅ Verificación de que no quedan nodos cordoned
- ✅ Reporte final de estado del cluster

**Limpieza manual:**
```bash
# Uncordon todos los nodos
kubectl get nodes -o name | xargs -I {} kubectl uncordon {}

# Eliminar namespace de prueba
kubectl delete namespace drain-test

# Verificar
kubectl get nodes
kubectl get namespaces
```

---

## 📊 Resumen del Laboratorio

### Lo que Aprendiste

- ✅ Diferencia entre `cordon`, `drain` y `uncordon`
- ✅ Evacuar pods de forma segura sin downtime
- ✅ Manejar DaemonSets durante mantenimiento
- ✅ Trabajar con PodDisruptionBudgets
- ✅ Realizar mantenimiento de nodos en producción
- ✅ Troubleshooting de problemas comunes de drain

### Tiempo por Fase

| Fase | Tiempo |
|------|--------|
| **Setup de apps** | 5-8 min |
| **Cordon + verificación** | 3-5 min |
| **Drain + evacuación** | 5-10 min |
| **Mantenimiento (simulado)** | 5-10 min |
| **Uncordon + verificación** | 3-5 min |
| **TOTAL** | ~30-45 min |

### Comandos Clave para CKA

| Comando | Uso en Examen | Criticidad |
|---------|---------------|------------|
| `kubectl cordon <node>` | Prevenir scheduling | ⭐⭐⭐ |
| `kubectl drain <node> --ignore-daemonsets` | Mantenimiento de nodos | ⭐⭐⭐⭐⭐ |
| `kubectl uncordon <node>` | Restaurar nodo | ⭐⭐⭐⭐ |
| `kubectl get pdb` | Verificar PDBs | ⭐⭐⭐ |

---

## 🎯 Siguiente Paso

Continúa con: **[Lab 04: Certificate Management](../lab-04-certificate-management/README.md)**

Aprenderás a:
- Gestionar certificados TLS de Kubernetes
- Verificar expiración de certificados
- Renovar certificados con kubeadm
- Troubleshooting de problemas de certificados

---

**🎓 ¡Excelente trabajo!** Has completado el laboratorio de mantenimiento de nodos.

**Nivel de complejidad**: ⭐⭐ Intermedio  
**Relevancia CKA**: 🔴 CRÍTICO (15% del examen - Node Maintenance)  
**Habilidades adquiridas**: Node maintenance, graceful eviction, PDB handling

---

*Laboratorio creado para el curso Kubernetes CKA/CKAD - Módulo 23: Maintenance & Upgrades*  
*Versión: 1.0 | Fecha: 2025-11-13*
