# Lab 01: etcd Backup y Restore

**Duración estimada:** 30-45 minutos  
**Dificultad:** ⭐⭐⭐ Avanzado  
**Relevancia CKA:** 🔴 CRÍTICO (Troubleshooting 30%)

---

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio, serás capaz de:

- ✅ Realizar backup completo de etcd usando `etcdctl`
- ✅ Restaurar un cluster desde un snapshot de etcd
- ✅ Verificar la integridad de backups de etcd
- ✅ Automatizar procedimientos de backup/restore
- ✅ Entender el almacenamiento de estado en Kubernetes
- ✅ Diagnosticar problemas de pérdida de datos

---

## 📋 Prerequisitos

Antes de comenzar, asegúrate de:

1. ✅ Tener un cluster Kubernetes funcional (kubeadm o similar)
2. ✅ Acceso SSH al nodo control plane
3. ✅ Permisos de root o sudo en el control plane
4. ✅ Familiaridad con línea de comandos Linux
5. ✅ Conocimiento básico de etcd y su rol en K8s

**Verifica prerequisitos:**
```bash
# Verificar acceso a etcd
kubectl get pods -n kube-system | grep etcd

# Verificar versión de etcdctl
ETCDCTL_API=3 etcdctl version

# Verificar espacio en disco (necesitas ~500MB)
df -h /var/lib/etcd
```

📖 **Ver detalles completos**: [SETUP.md](./SETUP.md)

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                    CONTROL PLANE NODE                        │
│                                                              │
│  ┌────────────────┐         ┌──────────────────┐           │
│  │  API Server    │◄────────┤  etcd (Primary)  │           │
│  │  (6443)        │  Estado │  (2379)          │           │
│  └────────────────┘         └──────────────────┘           │
│                                     │                        │
│                                     │ Snapshot               │
│                                     ▼                        │
│                             ┌──────────────────┐            │
│                             │  Backup File     │            │
│                             │  /backup/        │            │
│                             │  snapshot.db     │            │
│                             └──────────────────┘            │
│                                     │                        │
│                                     │ Restore                │
│                                     ▼                        │
│                             ┌──────────────────┐            │
│                             │  etcd (Restored) │            │
│                             │  /var/lib/etcd-  │            │
│                             │  restored/       │            │
│                             └──────────────────┘            │
└─────────────────────────────────────────────────────────────┘

FLUJO DE BACKUP:
1. etcdctl snapshot save → /backup/snapshot-YYYYMMDD.db
2. etcdctl snapshot status → Verificar integridad
3. Copiar a almacenamiento externo (opcional)

FLUJO DE RESTORE:
1. Detener API server temporalmente
2. etcdctl snapshot restore → /var/lib/etcd-restored
3. Actualizar manifest de etcd
4. Reiniciar etcd con datos restaurados
```

---

## 📚 Conceptos Clave

### ¿Qué es etcd?

**etcd** es una base de datos clave-valor distribuida que almacena **TODO el estado del cluster Kubernetes**:

- 🗂️ **Configuración de recursos**: Pods, Services, ConfigMaps, Secrets
- 👥 **RBAC**: Roles, RoleBindings, ServiceAccounts
- 🔧 **Estado del cluster**: Nodes, Events, Leases
- 📦 **Custom Resources**: CRDs y sus instancias

**Sin etcd funcional = Cluster completamente no operacional** ⚠️

### ¿Por qué hacer backups de etcd?

**Escenarios de recuperación críticos**:

1. **Pérdida de datos**: Corrupción de disco, eliminación accidental
2. **Disaster recovery**: Fallo completo del datacenter
3. **Rollback de configuración**: Revertir cambios masivos erróneos
4. **Migración de cluster**: Mover estado a nuevo cluster
5. **Auditoría**: Investigar estado histórico del cluster

**Frecuencia recomendada**:
- ✅ **Producción**: Cada 4-6 horas + antes de cambios mayores
- ✅ **Staging**: Diario
- ✅ **Desarrollo**: Semanal

---

## 🛠️ Procedimiento del Laboratorio

### Parte 1: Preparar el Entorno

#### Paso 1.1: Crear datos de prueba

```bash
# Crear namespace de prueba
kubectl create namespace backup-test

# Crear varios recursos para validar el backup
kubectl create deployment nginx-backup --image=nginx:alpine \
  --replicas=3 -n backup-test

# Crear ConfigMap con datos
kubectl create configmap backup-config \
  --from-literal=database=production \
  --from-literal=version=1.0.0 \
  -n backup-test

# Crear Secret
kubectl create secret generic backup-secret \
  --from-literal=password=super-secret-123 \
  -n backup-test

# Verificar recursos creados
kubectl get all,cm,secret -n backup-test
```

**✅ Verificación esperada:**
```
NAME                                READY   STATUS    RESTARTS   AGE
pod/nginx-backup-xxxxxxxxx-xxxxx    1/1     Running   0          10s
pod/nginx-backup-xxxxxxxxx-xxxxx    1/1     Running   0          10s
pod/nginx-backup-xxxxxxxxx-xxxxx    1/1     Running   0          10s

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-backup   3/3     3            3           10s

NAME                                      DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-backup-xxxxxxxxx   3         3         3       10s

NAME                      DATA   AGE
configmap/backup-config   2      5s

NAME                    TYPE     DATA   AGE
secret/backup-secret    Opaque   1      3s
```

#### Paso 1.2: Obtener información de etcd

```bash
# SSH al nodo control plane (si estás usando cluster remoto)
# ssh user@control-plane-node

# Identificar el pod de etcd
sudo kubectl get pods -n kube-system -l component=etcd -o wide

# Obtener configuración de etcd desde el manifest
sudo cat /etc/kubernetes/manifests/etcd.yaml | grep -E "cert|key|server"
```

**Variables importantes** (guarda para uso posterior):

```bash
# Exportar variables de etcd (ajusta según tu cluster)
export ETCDCTL_API=3
export ETCD_CACERT=/etc/kubernetes/pki/etcd/ca.crt
export ETCD_CERT=/etc/kubernetes/pki/etcd/server.crt
export ETCD_KEY=/etc/kubernetes/pki/etcd/server.key
export ETCD_ENDPOINTS=https://127.0.0.1:2379

# Verificar conectividad a etcd
sudo ETCDCTL_API=3 etcdctl \
  --cacert=$ETCD_CACERT \
  --cert=$ETCD_CERT \
  --key=$ETCD_KEY \
  --endpoints=$ETCD_ENDPOINTS \
  endpoint health
```

**✅ Output esperado:**
```
https://127.0.0.1:2379 is healthy: successfully committed proposal: took = 2.345ms
```

---

### Parte 2: Realizar Backup de etcd

#### Paso 2.1: Crear directorio de backups

```bash
# Crear directorio con permisos apropiados
sudo mkdir -p /var/lib/etcd-backup
sudo chmod 700 /var/lib/etcd-backup

# Verificar espacio disponible
df -h /var/lib/etcd-backup
```

#### Paso 2.2: Ejecutar snapshot manual

```bash
# Crear snapshot con timestamp
BACKUP_FILE="/var/lib/etcd-backup/snapshot-$(date +%Y%m%d-%H%M%S).db"

sudo ETCDCTL_API=3 etcdctl snapshot save $BACKUP_FILE \
  --cacert=$ETCD_CACERT \
  --cert=$ETCD_CERT \
  --key=$ETCD_KEY \
  --endpoints=$ETCD_ENDPOINTS

echo "Backup creado en: $BACKUP_FILE"
```

**✅ Output esperado:**
```
{"level":"info","ts":"2025-11-13T10:30:00Z","caller":"snapshot/v3_snapshot.go:65","msg":"created temporary db file","path":"/var/lib/etcd-backup/snapshot-20251113-103000.db.part"}
{"level":"info","ts":"2025-11-13T10:30:01Z","logger":"client","caller":"v3/maintenance.go:211","msg":"opened snapshot stream; downloading"}
{"level":"info","ts":"2025-11-13T10:30:01Z","caller":"snapshot/v3_snapshot.go:73","msg":"fetching snapshot","endpoint":"https://127.0.0.1:2379"}
{"level":"info","ts":"2025-11-13T10:30:02Z","logger":"client","caller":"v3/maintenance.go:219","msg":"completed snapshot read; closing"}
Snapshot saved at /var/lib/etcd-backup/snapshot-20251113-103000.db
```

#### Paso 2.3: Verificar integridad del backup

```bash
# Verificar status del snapshot
sudo ETCDCTL_API=3 etcdctl snapshot status $BACKUP_FILE --write-out=table

# Obtener tamaño del archivo
ls -lh $BACKUP_FILE
```

**✅ Output esperado:**
```
+---------+----------+------------+------------+
|  HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+---------+----------+------------+------------+
| 1a2b3c4d|    12345 |       1234 |     15 MB  |
+---------+----------+------------+------------+

-rw------- 1 root root 15M Nov 13 10:30 /var/lib/etcd-backup/snapshot-20251113-103000.db
```

#### Paso 2.4: Usar script de automatización

```bash
# Copiar script de backup automatizado
sudo cp backup-etcd.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/backup-etcd.sh

# Ejecutar script
sudo /usr/local/bin/backup-etcd.sh

# Ver logs
sudo tail -f /var/log/etcd-backup.log
```

---

### Parte 3: Simular Pérdida de Datos

#### Paso 3.1: Eliminar recursos de prueba

```bash
# Eliminar el deployment (simula pérdida de datos)
kubectl delete deployment nginx-backup -n backup-test

# Eliminar el ConfigMap
kubectl delete configmap backup-config -n backup-test

# Verificar que ya no existen
kubectl get all,cm,secret -n backup-test
```

**✅ Verificación:**
```
NAME                    TYPE     DATA   AGE
secret/backup-secret    Opaque   1      5m
# El deployment y ConfigMap deben haber desaparecido
```

#### Paso 3.2: Intentar recuperar (sin restore)

```bash
# Verificar que no hay forma de recuperar los recursos eliminados
kubectl get deploy -n backup-test
# No resources found in backup-test namespace.

# Ahora procederemos a restaurar desde el backup
```

---

### Parte 4: Restaurar desde Backup

#### Paso 4.1: Detener componentes del control plane

⚠️ **ADVERTENCIA**: Este paso causa downtime del cluster (API no disponible)

```bash
# Mover manifests fuera del directorio de kubelet
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sudo mv /etc/kubernetes/manifests/kube-controller-manager.yaml /tmp/
sudo mv /etc/kubernetes/manifests/kube-scheduler.yaml /tmp/

# Esperar a que los pods se detengan
sleep 10

# Verificar que API server está detenido
kubectl get nodes 2>&1 | grep "connection refused"
```

#### Paso 4.2: Restaurar snapshot de etcd

```bash
# Definir directorio de restore
RESTORE_DIR="/var/lib/etcd-restored"

# Ejecutar restore (usa el archivo de backup más reciente)
LATEST_BACKUP=$(ls -t /var/lib/etcd-backup/snapshot-*.db | head -1)

sudo ETCDCTL_API=3 etcdctl snapshot restore $LATEST_BACKUP \
  --data-dir=$RESTORE_DIR \
  --name=default \
  --initial-cluster=default=https://127.0.0.1:2380 \
  --initial-advertise-peer-urls=https://127.0.0.1:2380 \
  --initial-cluster-token=etcd-cluster-1

echo "Restore completado en: $RESTORE_DIR"
```

**✅ Output esperado:**
```
{"level":"info","ts":"2025-11-13T10:35:00Z","caller":"snapshot/v3_snapshot.go:251","msg":"restoring snapshot","path":"/var/lib/etcd-backup/snapshot-20251113-103000.db","wal-dir":"/var/lib/etcd-restored/member/wal","data-dir":"/var/lib/etcd-restored","snap-dir":"/var/lib/etcd-restored/member/snap"}
{"level":"info","ts":"2025-11-13T10:35:01Z","caller":"mvcc/kvstore.go:415","msg":"restored last compact revision","meta-bucket-name":"meta","meta-bucket-name-key":"finishedCompactRev","restored-compact-revision":12000}
{"level":"info","ts":"2025-11-13T10:35:01Z","caller":"membership/cluster.go:421","msg":"added member","cluster-id":"abcd1234","local-member-id":"0","added-peer-id":"efgh5678","added-peer-peer-urls":["https://127.0.0.1:2380"]}
```

#### Paso 4.3: Actualizar configuración de etcd

```bash
# Backup del manifest original
sudo cp /etc/kubernetes/manifests/etcd.yaml /tmp/etcd.yaml.bak

# Editar manifest para apuntar al nuevo data-dir
sudo sed -i 's|/var/lib/etcd|/var/lib/etcd-restored|g' \
  /tmp/etcd.yaml

# NOTA: También debes actualizar --initial-cluster-token si es necesario
```

**Edición manual alternativa:**

```bash
sudo nano /tmp/etcd.yaml
```

Buscar y modificar:
```yaml
# ANTES:
- --data-dir=/var/lib/etcd

# DESPUÉS:
- --data-dir=/var/lib/etcd-restored
```

#### Paso 4.4: Reiniciar control plane

```bash
# Mover manifest de etcd modificado
sudo mv /tmp/etcd.yaml /etc/kubernetes/manifests/

# Esperar a que etcd inicie (30-60 segundos)
sleep 60

# Restaurar otros componentes
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
sudo mv /tmp/kube-controller-manager.yaml /etc/kubernetes/manifests/
sudo mv /tmp/kube-scheduler.yaml /etc/kubernetes/manifests/

# Esperar a que todos los componentes inicien
sleep 30
```

#### Paso 4.5: Verificar que el cluster está operacional

```bash
# Verificar nodos
kubectl get nodes

# Verificar componentes del control plane
kubectl get pods -n kube-system

# CRÍTICO: Verificar que los recursos eliminados están restaurados
kubectl get all,cm,secret -n backup-test
```

**✅ Verificación esperada - RECURSOS RESTAURADOS:**
```
NAME                                READY   STATUS    RESTARTS   AGE
pod/nginx-backup-xxxxxxxxx-xxxxx    1/1     Running   0          15m
pod/nginx-backup-xxxxxxxxx-xxxxx    1/1     Running   0          15m
pod/nginx-backup-xxxxxxxxx-xxxxx    1/1     Running   0          15m

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-backup   3/3     3            3           15m

NAME                      DATA   AGE
configmap/backup-config   2      15m

NAME                    TYPE     DATA   AGE
secret/backup-secret    Opaque   1      15m
```

🎉 **¡ÉXITO!** Los recursos eliminados han sido restaurados desde el backup.

#### Paso 4.6: Validar datos restaurados

```bash
# Verificar contenido del ConfigMap
kubectl get configmap backup-config -n backup-test -o yaml

# Verificar que el Secret existe (no mostrar contenido sensible)
kubectl get secret backup-secret -n backup-test

# Verificar logs de un pod restaurado
POD_NAME=$(kubectl get pods -n backup-test -l app=nginx-backup -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME -n backup-test --tail=10
```

---

### Parte 5: Automatización de Backups

#### Paso 5.1: Configurar cron job para backups automáticos

```bash
# Editar crontab de root
sudo crontab -e

# Agregar backup cada 6 horas (a las 00:00, 06:00, 12:00, 18:00)
0 */6 * * * /usr/local/bin/backup-etcd.sh >> /var/log/etcd-backup.log 2>&1

# Agregar limpieza de backups antiguos (mantener últimos 7 días)
0 2 * * * find /var/lib/etcd-backup -name "snapshot-*.db" -mtime +7 -delete
```

#### Paso 5.2: Verificar script de backup automatizado

Ver el contenido del script: [backup-etcd.sh](./backup-etcd.sh)

```bash
# Testear el script manualmente
sudo /usr/local/bin/backup-etcd.sh

# Verificar que se creó el backup
ls -lth /var/lib/etcd-backup/ | head -5
```

#### Paso 5.3: Script de restore automatizado

Ver el contenido del script: [restore-etcd.sh](./restore-etcd.sh)

```bash
# Hacer ejecutable
sudo chmod +x restore-etcd.sh

# NO ejecutar en producción sin revisión previa
# El script incluye validaciones de seguridad
```

---

## 🧪 Validación del Laboratorio

### Checklist de Completitud

- [ ] **Backup creado exitosamente** con `etcdctl snapshot save`
- [ ] **Integridad verificada** con `etcdctl snapshot status`
- [ ] **Recursos de prueba** creados (deployment, configmap, secret)
- [ ] **Simulación de pérdida** de datos realizada
- [ ] **Restore ejecutado** desde snapshot
- [ ] **Cluster operacional** después del restore
- [ ] **Recursos restaurados** verificados en namespace backup-test
- [ ] **Scripts de automatización** configurados
- [ ] **Cron job** programado para backups periódicos
- [ ] **Cleanup ejecutado** (recursos de prueba eliminados)

### Comandos de Verificación Final

```bash
# 1. Verificar salud de etcd
sudo ETCDCTL_API=3 etcdctl endpoint health \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --endpoints=https://127.0.0.1:2379

# 2. Listar backups disponibles
ls -lh /var/lib/etcd-backup/

# 3. Verificar cron jobs configurados
sudo crontab -l | grep etcd

# 4. Verificar cluster funcional
kubectl get nodes
kubectl get pods -A | grep -E "Running|Pending"

# 5. Contar recursos totales en etcd
sudo ETCDCTL_API=3 etcdctl get / --prefix --keys-only \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --endpoints=https://127.0.0.1:2379 | wc -l
```

---

## 🔍 Troubleshooting

### Problema 1: "connection refused" al ejecutar etcdctl

**Síntomas:**
```
Error: context deadline exceeded
```

**Solución:**
```bash
# Verificar que etcd está corriendo
sudo crictl ps | grep etcd

# Verificar logs de etcd
sudo crictl logs <etcd-container-id>

# Verificar que los certificados son correctos
ls -l /etc/kubernetes/pki/etcd/

# Asegurarte de usar ETCDCTL_API=3
export ETCDCTL_API=3
```

---

### Problema 2: Snapshot save falla con "permission denied"

**Síntomas:**
```bash
Error: open /var/lib/etcd-backup/snapshot.db: permission denied
```

**Solución:**
```bash
# Verificar permisos del directorio
sudo ls -ld /var/lib/etcd-backup

# Crear con permisos correctos si no existe
sudo mkdir -p /var/lib/etcd-backup
sudo chmod 700 /var/lib/etcd-backup
sudo chown root:root /var/lib/etcd-backup

# Ejecutar etcdctl con sudo
sudo ETCDCTL_API=3 etcdctl snapshot save ...
```

---

### Problema 3: Cluster no inicia después del restore

**Síntomas:**
```bash
kubectl get nodes
# The connection to the server was refused
```

**Diagnóstico:**
```bash
# 1. Verificar logs de kubelet
sudo journalctl -u kubelet -f

# 2. Verificar manifest de etcd
sudo cat /etc/kubernetes/manifests/etcd.yaml | grep data-dir

# 3. Verificar permisos del directorio restored
sudo ls -ld /var/lib/etcd-restored
sudo chown -R root:root /var/lib/etcd-restored

# 4. Verificar logs de contenedor etcd
sudo crictl logs <etcd-container-id> 2>&1 | tail -50
```

**Solución - Rollback si es necesario:**
```bash
# 1. Detener componentes
sudo mv /etc/kubernetes/manifests/*.yaml /tmp/

# 2. Restaurar manifest original de etcd
sudo cp /tmp/etcd.yaml.bak /etc/kubernetes/manifests/etcd.yaml

# 3. Eliminar directorio restored problemático
sudo rm -rf /var/lib/etcd-restored

# 4. Reiniciar componentes
sudo mv /tmp/kube-*.yaml /etc/kubernetes/manifests/

# 5. Esperar a que el cluster se recupere
sleep 60
kubectl get nodes
```

---

### Problema 4: Error "cluster ID mismatch"

**Síntomas:**
```
error: "cluster ID mismatch"
```

**Solución:**
```bash
# Durante restore, asegúrate de usar --initial-cluster-token único
sudo ETCDCTL_API=3 etcdctl snapshot restore $BACKUP_FILE \
  --data-dir=/var/lib/etcd-restored \
  --initial-cluster-token=etcd-cluster-restored-$(date +%s)
  
# Actualizar manifest con el nuevo token
sudo nano /etc/kubernetes/manifests/etcd.yaml
# Agregar: --initial-cluster-token=etcd-cluster-restored-XXXXXXXXXX
```

---

### Problema 5: Backup muy grande (>1GB)

**Causa:** El cluster tiene muchos recursos o historial largo de eventos.

**Solución:**
```bash
# 1. Limpiar eventos antiguos antes del backup
kubectl delete events --all-namespaces --field-selector=involvedObject.kind=Pod

# 2. Compactar historial de etcd
sudo ETCDCTL_API=3 etcdctl compact \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --endpoints=https://127.0.0.1:2379 \
  $(sudo ETCDCTL_API=3 etcdctl endpoint status --write-out="json" \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    --endpoints=https://127.0.0.1:2379 \
    | jq -r '.[0].Status.header.revision')

# 3. Defragmentar etcd
sudo ETCDCTL_API=3 etcdctl defrag \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --endpoints=https://127.0.0.1:2379

# 4. Ahora crear backup (será más pequeño)
```

---

## 📚 Recursos Adicionales

### Documentación Oficial

- [Kubernetes - Operating etcd clusters](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/)
- [etcd - Disaster recovery](https://etcd.io/docs/v3.5/op-guide/recovery/)
- [etcdctl snapshot commands](https://etcd.io/docs/v3.5/op-guide/maintenance/)

### Comandos Útiles de etcd

```bash
# Verificar miembros del cluster etcd
sudo ETCDCTL_API=3 etcdctl member list \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --endpoints=https://127.0.0.1:2379

# Ver métricas de etcd
curl -k --cert /etc/kubernetes/pki/etcd/server.crt \
  --key /etc/kubernetes/pki/etcd/server.key \
  --cacert /etc/kubernetes/pki/etcd/ca.crt \
  https://127.0.0.1:2379/metrics | grep -E "etcd_server_has_leader|etcd_mvcc_db_total_size"

# Obtener revisión actual
sudo ETCDCTL_API=3 etcdctl endpoint status --write-out=table \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --endpoints=https://127.0.0.1:2379
```

### Best Practices

**Backups:**
- ✅ Automatizar con cron jobs
- ✅ Mantener múltiples versiones (7-30 días)
- ✅ Almacenar en ubicación externa al cluster
- ✅ Cifrar backups en reposo
- ✅ Probar procedimiento de restore regularmente

**Seguridad:**
- ✅ Proteger certificados de etcd (chmod 600)
- ✅ Restringir acceso SSH al control plane
- ✅ Auditar accesos a etcd
- ✅ Usar TLS para todas las comunicaciones

**Monitoreo:**
- ✅ Alertar si backup falla
- ✅ Monitorear tamaño de etcd
- ✅ Verificar latencia de etcd
- ✅ Tracking de revisiones

---

## 🎓 Conceptos para el Examen CKA

### Puntos Críticos para CKA

1. **Comando de backup** (MEMORIZAR):
   ```bash
   ETCDCTL_API=3 etcdctl snapshot save /backup/snapshot.db \
     --cacert=<ca-cert> --cert=<cert> --key=<key> --endpoints=<endpoint>
   ```

2. **Comando de restore** (MEMORIZAR):
   ```bash
   ETCDCTL_API=3 etcdctl snapshot restore /backup/snapshot.db \
     --data-dir=/var/lib/etcd-restored
   ```

3. **Ubicación de certificados** (CONOCER):
   - CA cert: `/etc/kubernetes/pki/etcd/ca.crt`
   - Server cert: `/etc/kubernetes/pki/etcd/server.crt`
   - Server key: `/etc/kubernetes/pki/etcd/server.key`

4. **Verificación de integridad**:
   ```bash
   ETCDCTL_API=3 etcdctl snapshot status snapshot.db --write-out=table
   ```

5. **Manifest de etcd**: `/etc/kubernetes/manifests/etcd.yaml`

### Escenarios de Examen

**Tarea típica CKA**:
> "Realiza un backup de etcd y guárdalo en /opt/etcd-backup/snapshot.db"

**Solución en 3 pasos**:
```bash
# 1. Exportar variables
export ETCDCTL_API=3

# 2. Obtener cert paths del manifest
grep -E "cert|key|server" /etc/kubernetes/manifests/etcd.yaml

# 3. Ejecutar backup
sudo etcdctl snapshot save /opt/etcd-backup/snapshot.db \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --endpoints=https://127.0.0.1:2379
```

**Tiempo en examen**: 3-5 minutos (backup) | 8-12 minutos (restore completo)

---

## 🧹 Limpieza del Laboratorio

**IMPORTANTE**: Ejecuta el script de cleanup para restaurar el estado original.

```bash
# Ejecutar script de limpieza
./cleanup.sh
```

El script realizará:
- ✅ Eliminar namespace `backup-test` y todos sus recursos
- ✅ Eliminar backups de prueba en `/var/lib/etcd-backup`
- ✅ Restaurar manifest original de etcd (si fue modificado)
- ✅ Eliminar cron jobs de backup (opcional)
- ✅ Restaurar etcd al data-dir original `/var/lib/etcd`

**Verificación post-cleanup:**
```bash
# Verificar que el namespace fue eliminado
kubectl get ns backup-test
# Error from server (NotFound): namespaces "backup-test" not found ✅

# Verificar que etcd usa el data-dir original
sudo cat /etc/kubernetes/manifests/etcd.yaml | grep data-dir
# --data-dir=/var/lib/etcd ✅

# Verificar cluster funcional
kubectl get nodes
# All nodes should be Ready ✅
```

---

## 📊 Resumen del Laboratorio

### Lo que Aprendiste

- ✅ Realizar backups de etcd con `etcdctl snapshot save`
- ✅ Verificar integridad de snapshots con `snapshot status`
- ✅ Restaurar cluster desde backup con `snapshot restore`
- ✅ Automatizar backups con scripts y cron
- ✅ Troubleshooting de problemas de restore
- ✅ Entender arquitectura de almacenamiento de K8s

### Comandos Clave

| Operación | Comando |
|-----------|---------|
| **Backup** | `etcdctl snapshot save snapshot.db` |
| **Verificar** | `etcdctl snapshot status snapshot.db` |
| **Restore** | `etcdctl snapshot restore snapshot.db --data-dir=/new/path` |
| **Health** | `etcdctl endpoint health` |
| **Status** | `etcdctl endpoint status --write-out=table` |

### Tiempo Total

- ⏱️ **Setup**: 5-10 minutos
- ⏱️ **Backup**: 10-15 minutos
- ⏱️ **Restore**: 15-20 minutos
- ⏱️ **Troubleshooting**: 5-10 minutos
- ⏱️ **Cleanup**: 3-5 minutos
- **TOTAL**: ~40-60 minutos

---

## 🎯 Siguiente Paso

Continúa con: **[Lab 02: Cluster Upgrade](../lab-02-cluster-upgrade-minor/README.md)**

Aprenderás a:
- Actualizar cluster de Kubernetes 1.27 → 1.28
- Upgrade de control plane con kubeadm
- Upgrade de worker nodes sin downtime
- Rollback en caso de problemas

---

**🎓 ¡Excelente trabajo!** Has completado uno de los laboratorios más críticos para CKA.

**Nivel de complejidad**: ⭐⭐⭐ Avanzado  
**Relevancia CKA**: 🔴 CRÍTICO (30% del examen - Troubleshooting)  
**Habilidades adquiridas**: Disaster Recovery, etcd operations, Cluster backup/restore

---

*Laboratorio creado para el curso Kubernetes CKA/CKAD - Módulo 23: Maintenance & Upgrades*  
*Versión: 1.0 | Fecha: 2025-11-13*
