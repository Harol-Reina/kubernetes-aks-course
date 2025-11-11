# Ejemplos Prácticos - Módulo 15: Volúmenes en Kubernetes

Este directorio contiene ejemplos prácticos organizados por tipo de volumen y concepto. Cada ejemplo incluye:
- Manifiestos YAML completos y listos para usar
- Comentarios explicativos detallados
- Comandos de prueba y verificación
- Mejores prácticas y advertencias

## 📂 Estructura de Ejemplos

```
ejemplos/
├── 01-emptydir/          # Volúmenes temporales a nivel de Pod
├── 02-hostpath/          # Volúmenes del sistema de archivos del nodo
├── 03-pvc-basico/        # PVC con provisioning dinámico en Azure
├── 04-pv-pvc-manual/     # Provisioning manual y binding avanzado
├── 05-access-modes/      # Modos de acceso (RWO, ROX, RWX)
└── 06-reclaim-policies/  # Políticas de recuperación (Retain, Delete)
```

---

## 📁 01-emptydir - Volúmenes Temporales

**Concepto**: Volúmenes temporales que existen mientras el Pod esté activo. Se eliminan cuando el Pod se elimina.

### Archivos Disponibles

#### [`pod-emptydir-basic.yaml`](01-emptydir/pod-emptydir-basic.yaml)
**Descripción**: Ejemplo básico de dos contenedores compartiendo un volumen emptyDir.

**Casos de uso**:
- Compartir datos entre contenedores del mismo Pod
- Patrón writer/reader o producer/consumer
- Datos temporales que no necesitan persistir

**Características**:
- 2 contenedores: `writer` y `reader`
- Writer escribe archivos cada 5 segundos
- Reader lee y muestra el contenido

**Probar**:
```bash
kubectl apply -f 01-emptydir/pod-emptydir-basic.yaml
kubectl logs pod-emptydir-basic -c writer
kubectl logs pod-emptydir-basic -c reader
```

---

#### [`pod-emptydir-memory.yaml`](01-emptydir/pod-emptydir-memory.yaml)
**Descripción**: emptyDir en memoria RAM (tmpfs) con límite de tamaño.

**Casos de uso**:
- Caché ultra-rápida en memoria
- Datos sensibles que no deben tocar disco
- Procesamiento de datos en memoria

**Características**:
- `medium: Memory` - Montado en RAM
- `sizeLimit: 128Mi` - Límite de memoria
- Alto rendimiento, pero volátil

**⚠️ Advertencias**:
- Consume memoria del nodo
- Se pierde al reiniciar el Pod
- Cuenta contra el límite de memoria del contenedor

**Probar**:
```bash
kubectl apply -f 01-emptydir/pod-emptydir-memory.yaml
kubectl exec pod-emptydir-memory -- df -h /cache
kubectl exec pod-emptydir-memory -- mount | grep cache
```

---

#### [`deployment-nginx-cache.yaml`](01-emptydir/deployment-nginx-cache.yaml)
**Descripción**: Nginx con contenedor sidecar procesando logs usando emptyDir compartido.

**Casos de uso**:
- Patrón sidecar para procesamiento de logs
- Nginx + procesador de logs
- Caché compartido entre contenedores

**Características**:
- Deployment con 2 contenedores por Pod
- Nginx sirve contenido y escribe logs
- Sidecar procesa y analiza logs en tiempo real
- Volumen emptyDir compartido para cache y logs

**Probar**:
```bash
kubectl apply -f 01-emptydir/deployment-nginx-cache.yaml
kubectl get pods -l app=nginx-cache
kubectl logs -l app=nginx-cache -c nginx
kubectl logs -l app=nginx-cache -c log-processor
```

---

## 📁 02-hostpath - Volúmenes del Nodo

**Concepto**: Montar un directorio del sistema de archivos del nodo en el Pod.

**⚠️ ADVERTENCIA**: Solo para casos específicos. NO recomendado para aplicaciones normales.

### Archivos Disponibles

#### [`pod-hostpath-basic.yaml`](02-hostpath/pod-hostpath-basic.yaml)
**Descripción**: Ejemplo básico de hostPath montando directorios del nodo.

**Casos de uso legítimos**:
- Acceder a Docker socket (`/var/run/docker.sock`)
- Acceder a logs del sistema
- Herramientas de monitoreo/debugging

**⚠️ Problemas de seguridad**:
- Acceso directo al filesystem del nodo
- Riesgo de escape de contenedor
- No portátil entre nodos

**Probar**:
```bash
kubectl apply -f 02-hostpath/pod-hostpath-basic.yaml
kubectl exec pod-hostpath-basic -- ls -lh /host-data
kubectl exec pod-hostpath-basic -- ls -lh /host-logs
```

---

#### [`daemonset-log-collector.yaml`](02-hostpath/daemonset-log-collector.yaml)
**Descripción**: DaemonSet que recopila logs del nodo (caso legítimo de hostPath).

**Casos de uso**:
- Recopilación de logs del sistema
- Agentes de monitoreo (Prometheus node-exporter)
- Herramientas de seguridad

**Características**:
- DaemonSet (uno por nodo)
- Monta `/var/log` del nodo en modo solo lectura
- Tolerations para ejecutar en todos los nodos

**✅ Uso legítimo**: Herramientas de infraestructura que DEBEN acceder al nodo.

**Probar**:
```bash
kubectl apply -f 02-hostpath/daemonset-log-collector.yaml
kubectl get daemonset log-collector
kubectl logs -l app=log-collector --tail=20
```

---

#### [`pod-hostpath-types.yaml`](02-hostpath/pod-hostpath-types.yaml)
**Descripción**: Demostración de los diferentes tipos de hostPath.

**Tipos de hostPath**:
- `DirectoryOrCreate`: Crea directorio si no existe
- `FileOrCreate`: Crea archivo si no existe
- `Directory`: Directorio debe existir
- `File`: Archivo debe existir
- `Socket`: Socket Unix debe existir

**Probar**:
```bash
kubectl apply -f 02-hostpath/pod-hostpath-types.yaml
kubectl logs pod-hostpath-types
kubectl describe pod pod-hostpath-types
```

---

## 📁 03-pvc-basico - Provisioning Dinámico en Azure

**Concepto**: Solicitar almacenamiento persistente usando PVC. Kubernetes crea automáticamente el PV y el disco en Azure.

### Archivos Disponibles

#### [`pvc-dynamic-azure.yaml`](03-pvc-basico/pvc-dynamic-azure.yaml)
**Descripción**: PVC básico con provisioning dinámico usando Azure Disk Standard SSD.

**StorageClass**: `managed-csi` (Azure Disk Standard SSD)

**Casos de uso**:
- Almacenamiento persistente básico
- Aplicaciones stateful (1 réplica)
- Bases de datos pequeñas

**Características**:
- 10 GiB de almacenamiento
- ReadWriteOnce (un solo nodo)
- Provisioning automático

**Probar persistencia**:
```bash
kubectl apply -f 03-pvc-basico/pvc-dynamic-azure.yaml
kubectl get pvc pvc-dynamic-azure
kubectl exec pod-with-pvc -- cat /data/persistent-data.txt
# Eliminar Pod
kubectl delete pod pod-with-pvc
# Recrear Pod
kubectl apply -f 03-pvc-basico/pvc-dynamic-azure.yaml
# Datos siguen ahí ✅
kubectl exec pod-with-pvc -- cat /data/persistent-data.txt
```

---

#### [`deployment-postgres-pvc.yaml`](03-pvc-basico/deployment-postgres-pvc.yaml)
**Descripción**: PostgreSQL con almacenamiento persistente en Azure Disk.

**Casos de uso**:
- Base de datos de producción
- Datos que deben sobrevivir reinicios
- Aplicaciones stateful

**Características**:
- PostgreSQL Alpine
- 20 GiB de almacenamiento
- Health checks (liveness/readiness)
- Service ClusterIP

**Probar persistencia**:
```bash
kubectl apply -f 03-pvc-basico/deployment-postgres-pvc.yaml
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s

# Conectar y crear datos
kubectl run psql-client --rm -it --image=postgres:alpine -- \
  psql -h postgres -U admin -d myapp
# Dentro de psql:
# CREATE TABLE test (id serial, data text);
# INSERT INTO test (data) VALUES ('Datos persistentes');
# SELECT * FROM test;
# \q

# Eliminar Pod
kubectl delete pod -l app=postgres
# Esperar a que se recree
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s

# Verificar datos
kubectl run psql-client --rm -it --image=postgres:alpine -- \
  psql -h postgres -U admin -d myapp -c "SELECT * FROM test;"
# ✅ Datos siguen ahí
```

---

#### [`pvc-premium-ssd.yaml`](03-pvc-basico/pvc-premium-ssd.yaml)
**Descripción**: PVC con Azure Disk Premium para alto rendimiento.

**StorageClass**: `managed-csi-premium` (Azure Disk Premium SSD)

**Casos de uso**:
- Bases de datos de producción con alta carga
- Aplicaciones que requieren IOPS elevados
- Baja latencia crítica

**Características**:
- 128 GiB (mínimo para Premium)
- Hasta 20,000 IOPS
- Hasta 900 MB/s throughput
- Latencia < 1ms

**💰 Costo**: Más elevado que Standard SSD

**Probar**:
```bash
kubectl apply -f 03-pvc-basico/pvc-premium-ssd.yaml
kubectl get pvc pvc-premium-ssd
kubectl describe pvc pvc-premium-ssd | grep StorageClass
# managed-csi-premium ✅
```

---

#### [`pvc-azure-files.yaml`](03-pvc-basico/pvc-azure-files.yaml)
**Descripción**: PVC con Azure Files (ReadWriteMany) compartido entre múltiples Pods.

**StorageClass**: `azurefile-csi` (Azure Files Standard)

**Casos de uso**:
- WordPress con múltiples réplicas (directorio uploads/)
- CMS con media compartido
- Logs centralizados
- Procesamiento distribuido de archivos

**Características**:
- 100 GiB compartido
- ReadWriteMany (múltiples nodos)
- Deployment con 3 réplicas
- Todos los Pods ven los mismos archivos

**Probar**:
```bash
kubectl apply -f 03-pvc-basico/pvc-azure-files.yaml
kubectl get pods -l app=shared-storage -o wide

# Ver archivos compartidos desde cada Pod
for pod in $(kubectl get pods -l app=shared-storage -o name); do
  echo "=== $pod ==="
  kubectl exec $pod -- ls -lh /shared-data/
done
# ✅ Todos ven los mismos archivos
```

---

#### [`storageclass-custom.yaml`](03-pvc-basico/storageclass-custom.yaml)
**Descripción**: StorageClass personalizada con parámetros avanzados.

**Características**:
- Premium SSD con replicación local
- Cache de lectura habilitado
- Política Retain (protege datos)
- Expansión de volumen permitida
- Permisos personalizados (uid/gid)

**Casos de uso**:
- Control total sobre parámetros de rendimiento
- Políticas específicas de recuperación
- Configuraciones de seguridad personalizadas

**Probar**:
```bash
kubectl apply -f 03-pvc-basico/storageclass-custom.yaml
kubectl get storageclass fast-ssd-retain
kubectl describe storageclass fast-ssd-retain
```

---

## 📁 04-pv-pvc-manual - Provisioning Manual

**Concepto**: Crear PV manualmente apuntando a recursos existentes, luego vincular PVC usando selectors.

### Archivos Disponibles

#### [`pv-pvc-manual.yaml`](04-pv-pvc-manual/pv-pvc-manual.yaml)
**Descripción**: Binding manual básico de PV/PVC con Azure Disk existente.

**Casos de uso**:
- Migrar volúmenes existentes a Kubernetes
- Usar discos pre-aprovisionados
- Control total sobre el recurso de almacenamiento

**Características**:
- PV creado manualmente
- PVC con `storageClassName: ""` (binding manual)
- Selector con matchLabels
- Node Affinity para zona correcta

**⚠️ Requiere**: Disco Azure existente

**Probar**:
```bash
# 1. Crear disco en Azure (si no existe)
RESOURCE_GROUP=$(az aks show --name CLUSTER --resource-group RG --query nodeResourceGroup -o tsv)
az disk create --name manual-pv-disk --resource-group $RESOURCE_GROUP --size-gb 50

# 2. Obtener URI del disco
DISK_URI=$(az disk show --name manual-pv-disk --resource-group $RESOURCE_GROUP --query id -o tsv)

# 3. Editar YAML con el URI correcto
# 4. Aplicar
kubectl apply -f 04-pv-pvc-manual/pv-pvc-manual.yaml
kubectl get pv,pvc
# Ambos Bound ✅
```

---

#### [`pv-pvc-selectors.yaml`](04-pv-pvc-manual/pv-pvc-selectors.yaml)
**Descripción**: Binding selectivo usando matchLabels y matchExpressions.

**Casos de uso**:
- Múltiples PVs con diferentes características
- Vincular PVC a PV específico
- Separación por ambiente (dev/prod)
- Separación por equipo/proyecto

**Características**:
- 3 PVs con diferentes labels (environment, tier, team)
- 3 PVCs con selectors específicos
- matchLabels (AND lógico)
- matchExpressions (operadores In, Exists)

**Operadores disponibles**:
- `In`: valor está en lista
- `NotIn`: valor NO está en lista
- `Exists`: label existe
- `DoesNotExist`: label NO existe

**Probar**:
```bash
kubectl apply -f 04-pv-pvc-manual/pv-pvc-selectors.yaml
kubectl get pvc
# Verificar bindings correctos
kubectl describe pvc pvc-backend-dev | grep "Volume:"
kubectl describe pvc pvc-frontend-dev | grep "Volume:"
```

---

#### [`pv-pvc-nodeaffinity.yaml`](04-pv-pvc-manual/pv-pvc-nodeaffinity.yaml)
**Descripción**: Node Affinity para controlar en qué nodos se puede usar el volumen.

**Casos de uso**:
- Azure Disk es zonal (debe estar en misma zona que el nodo)
- Optimización de latencia
- Compliance (datos en región específica)
- Evitar errores de attach por zona incorrecta

**Características**:
- Node Affinity por zona (topology.disk.csi.azure.com/zone)
- Node Affinity por tipo de instancia
- Scheduler automáticamente programa Pod en nodo compatible
- Previene "FailedAttachVolume"

**Probar en cluster multi-zona**:
```bash
# Ver zonas de los nodos
kubectl get nodes -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.topology\\.disk\\.csi\\.azure\\.com/zone

kubectl apply -f 04-pv-pvc-manual/pv-pvc-nodeaffinity.yaml
kubectl get pod pod-zone-affinity -o wide
# Pod debe estar en nodo de la zona correcta ✅
```

---

#### [`pv-migration.yaml`](04-pv-pvc-manual/pv-migration.yaml)
**Descripción**: Migrar disco Azure existente a Kubernetes PV (guía completa).

**Casos de uso**:
- Migrar aplicación de VM a Kubernetes
- Recuperación de desastres
- Compartir datos entre clusters
- Usar datos existentes en Kubernetes

**Características**:
- Checklist completo de migración
- Pasos detallados con comandos az CLI
- Verificaciones de seguridad
- Política Retain para proteger datos

**Checklist de migración**:
1. ✅ Verificar que disco NO está en uso
2. ✅ Hacer backup (snapshot)
3. ✅ Verificar zona del disco
4. ✅ Verificar sistema de archivos (fsType)
5. ✅ Usar Retain policy
6. ✅ Probar en dev primero

**Probar**:
```bash
# Ver guía completa en el archivo YAML
# Incluye todos los comandos az necesarios
```

---

## 📁 05-access-modes - Modos de Acceso

**Concepto**: Controlar cómo los Pods pueden acceder al volumen.

**Modos disponibles**:
- **ReadWriteOnce (RWO)**: Un solo nodo puede montar (lectura-escritura)
- **ReadOnlyMany (ROX)**: Múltiples nodos pueden montar (solo lectura)
- **ReadWriteMany (RWX)**: Múltiples nodos pueden montar (lectura-escritura)

### Archivos Disponibles

#### [`rwo-readwriteonce.yaml`](05-access-modes/rwo-readwriteonce.yaml)
**Descripción**: ReadWriteOnce con Azure Disk - Solo un nodo puede montar.

**Compatibilidad**:
- ✅ Azure Disk (managed-csi, managed-csi-premium)
- ❌ NO soporta múltiples nodos

**Comportamiento**:
- Deployment 1 réplica: ✅ Funciona
- Deployment 3 réplicas mismo nodo: ✅ Funciona
- Deployment 3 réplicas diferentes nodos: ⚠️ Solo 1 Pod funciona

**Casos de uso**:
- Bases de datos single-instance
- Aplicaciones stateful con 1 réplica
- StatefulSets (cada Pod su propio PVC)

**Probar**:
```bash
kubectl apply -f 05-access-modes/rwo-readwriteonce.yaml
kubectl get pods -l instance=multi -o wide
# Ver en qué nodos están
# Si están en diferentes nodos, algunos quedarán Pending
kubectl describe pod <pod-pending>
# "Multi-Attach error" ⚠️
```

---

#### [`rwx-readwritemany.yaml`](05-access-modes/rwx-readwritemany.yaml)
**Descripción**: ReadWriteMany con Azure Files - Múltiples nodos pueden montar.

**Compatibilidad**:
- ✅ Azure Files (azurefile-csi, azurefile-csi-premium)
- ❌ Azure Disk NO soporta

**Casos de uso**:
- WordPress con múltiples réplicas
- CMS con media compartido
- Procesamiento distribuido de archivos
- Logs centralizados

**Características**:
- 5 Pods escritores
- 3 Pods lectores
- Todos pueden leer/escribir simultáneamente
- Funcionan en diferentes nodos ✅

**Probar**:
```bash
kubectl apply -f 05-access-modes/rwx-readwritemany.yaml
kubectl get pods -l app=rwx-demo -o wide
# 8 Pods total, posiblemente en diferentes nodos ✅

# Ver logs de escritores
kubectl logs -l role=writer --tail=20 --prefix

# Acceder a un reader
READER=$(kubectl get pod -l role=reader -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $READER -- sh
ls -lh /shared/pods/  # Ver directorios de todos los writers
cat /shared/global.log | tail -20
```

---

#### [`rox-readonlymany.yaml`](05-access-modes/rox-readonlymany.yaml)
**Descripción**: ReadOnlyMany - Distribuir datos estáticos a múltiples Pods.

**Flujo**:
1. Job escribe datos en volumen RWO
2. Crear PVC ROX apuntando a los mismos datos
3. Deployments leen datos en modo solo lectura

**Casos de uso**:
- Distribuir configuraciones estáticas
- Modelos de Machine Learning entrenados
- Assets estáticos (imágenes, CSS, JS)
- Datos de referencia (catálogos, diccionarios)

**Características**:
- Job prepara datos (escritura)
- Deployment con 5 réplicas (solo lectura)
- Escritura bloqueada (read-only filesystem)

**Probar**:
```bash
# Fase 1: Preparar datos
kubectl apply -f 05-access-modes/rox-readonlymany.yaml
kubectl wait --for=condition=complete job/data-loader --timeout=120s

# Fase 2: Distribuir en ROX
# (Editar YAML para aplicar Deployment)
kubectl apply -f 05-access-modes/rox-readonlymany.yaml
kubectl get pods -l app=readonly-consumer

# Intentar escribir (debe fallar)
POD=$(kubectl get pod -l app=readonly-consumer -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- sh -c 'echo "test" > /data/test.txt'
# Error: Read-only file system ✅
```

---

#### [`access-modes-comparison.yaml`](05-access-modes/access-modes-comparison.yaml)
**Descripción**: Suite de tests y tabla de compatibilidad Azure.

**Tabla de compatibilidad**:
| StorageClass              | RWO | ROX | RWX |
|---------------------------|-----|-----|-----|
| managed-csi (Disk)        | ✅  | ❌  | ❌  |
| managed-csi-premium       | ✅  | ❌  | ❌  |
| azurefile-csi (Files)     | ✅  | ✅  | ✅  |
| azurefile-csi-premium     | ✅  | ✅  | ✅  |

**Matriz de decisión**: Incluye guía de qué modo usar según caso de uso.

**Probar**:
```bash
kubectl apply -f 05-access-modes/access-modes-comparison.yaml
kubectl get pvc -l test=access-modes
# test-rwo-disk:       ✅ Bound
# test-rwx-disk-fail:  ❌ Pending (esperado)
# test-rwx-files:      ✅ Bound
# test-rox-files:      ✅ Bound

kubectl describe pvc test-rwx-disk-fail
# Error: storageclass does not support ReadWriteMany ✅
```

---

## 📁 06-reclaim-policies - Políticas de Recuperación

**Concepto**: Controlar qué sucede con el volumen cuando se elimina el PVC.

**Políticas disponibles**:
- **Retain**: PV NO se elimina, datos protegidos
- **Delete**: PV y disco se eliminan automáticamente
- **Recycle**: DEPRECATED (no usar)

### Archivos Disponibles

#### [`retain-policy.yaml`](06-reclaim-policies/retain-policy.yaml)
**Descripción**: Política Retain - Proteger datos al eliminar PVC.

**Flujo**:
1. Eliminar PVC → PV pasa a "Released"
2. Disco Azure NO se elimina
3. Datos intactos y recuperables
4. Requiere limpieza manual

**Casos de uso**:
- Bases de datos de producción
- Datos críticos de negocio
- Entornos regulados (compliance)
- Migración entre clusters

**Ventajas**:
- ✅ Protección contra eliminación accidental
- ✅ Recuperación de desastres
- ✅ Auditoría y cumplimiento

**Desventajas**:
- ❌ Requiere gestión manual
- ❌ PV queda "Released" (no reutilizable automáticamente)
- 💰 Costos: disco sigue facturándose

**Probar recuperación**:
```bash
kubectl apply -f 06-reclaim-policies/retain-policy.yaml
PV_NAME=$(kubectl get pvc pvc-important-data -o jsonpath='{.spec.volumeName}')

# Escribir datos
kubectl exec data-producer -- cat /data/production-data.txt

# Eliminar PVC
kubectl delete pvc pvc-important-data
kubectl get pv $PV_NAME
# STATUS: Released ✅ (protegido)

# Recuperar datos
kubectl patch pv $PV_NAME -p '{"spec":{"claimRef":null}}'
# Crear nuevo PVC
# Datos recuperados ✅
```

---

#### [`delete-policy.yaml`](06-reclaim-policies/delete-policy.yaml)
**Descripción**: Política Delete - Eliminar automáticamente volumen y disco.

**Flujo**:
1. Eliminar PVC → PV se elimina automáticamente
2. Disco Azure se elimina automáticamente
3. ✅ Limpieza completa, sin recursos huérfanos

**Casos de uso**:
- Datos temporales (caché, procesamiento)
- Entornos de desarrollo/testing
- CI/CD pipelines
- Datos respaldados externamente

**Ventajas**:
- ✅ Limpieza automática
- ✅ No deja discos huérfanos
- ✅ Reduce costos

**Desventajas**:
- ❌ Datos se pierden permanentemente
- ❌ Riesgo de eliminación accidental
- ❌ No hay recuperación sin backup

**Probar**:
```bash
kubectl apply -f 06-reclaim-policies/delete-policy.yaml
PV_NAME=$(kubectl get pvc pvc-temporary-data -o jsonpath='{.spec.volumeName}')
DISK_URI=$(kubectl get pv $PV_NAME -o jsonpath='{.spec.csi.volumeHandle}')

# Eliminar PVC
kubectl delete pvc pvc-temporary-data

# Verificar PV eliminado
kubectl get pv $PV_NAME
# Error: not found ✅

# Verificar disco eliminado en Azure
# (usar comando az disk show)
# Error: ResourceNotFound ✅
```

---

#### [`reclaim-comparison.yaml`](06-reclaim-policies/reclaim-comparison.yaml)
**Descripción**: Comparación lado a lado de Retain vs Delete.

**Escenarios incluidos**:
1. PostgreSQL Producción (Retain)
2. Redis Caché Desarrollo (Delete)
3. CI/CD Workspace (Delete)

**Matriz de decisión**:
| Aplicación                    | Política | Justificación          |
|-------------------------------|----------|------------------------|
| PostgreSQL/MySQL Producción   | Retain   | Datos críticos         |
| Redis caché desarrollo        | Delete   | Reconstruible          |
| CI/CD workspaces              | Delete   | Temporal               |
| Archivos de usuario           | Retain   | No recuperable         |
| Logs de auditoría             | Retain   | Compliance             |

**Probar**:
```bash
kubectl apply -f 06-reclaim-policies/reclaim-comparison.yaml

# Ver políticas
kubectl get storageclass prod-database-storage dev-cache-storage

# Probar eliminación con Delete
kubectl delete pvc pvc-dev-cache
# PV eliminado automáticamente ✅

# Probar eliminación con Retain
kubectl delete pvc pvc-prod-database
PV_PROD=$(kubectl get pv -o name | grep pvc-prod-database)
kubectl get $PV_PROD
# STATUS: Released ✅ (protegido)
```

---

## 🧪 Cómo Usar los Ejemplos

### Prerequisitos

1. **Cluster AKS activo**:
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

2. **StorageClasses predefinidas** (deben existir en AKS):
   ```bash
   kubectl get storageclass
   # managed-csi
   # managed-csi-premium
   # azurefile-csi
   # azurefile-csi-premium
   ```

3. **Azure CLI** (para ejemplos de migración):
   ```bash
   az --version
   az account show
   ```

### Flujo de Trabajo Recomendado

1. **Empezar con conceptos básicos**:
   ```bash
   # emptyDir (más simple)
   kubectl apply -f 01-emptydir/pod-emptydir-basic.yaml
   
   # PVC básico
   kubectl apply -f 03-pvc-basico/pvc-dynamic-azure.yaml
   ```

2. **Probar persistencia**:
   ```bash
   # PostgreSQL con datos persistentes
   kubectl apply -f 03-pvc-basico/deployment-postgres-pvc.yaml
   ```

3. **Explorar access modes**:
   ```bash
   # ReadWriteOnce
   kubectl apply -f 05-access-modes/rwo-readwriteonce.yaml
   
   # ReadWriteMany
   kubectl apply -f 05-access-modes/rwx-readwritemany.yaml
   ```

4. **Entender reclaim policies**:
   ```bash
   # Comparación completa
   kubectl apply -f 06-reclaim-policies/reclaim-comparison.yaml
   ```

### Limpieza

Para limpiar todos los recursos de un ejemplo:

```bash
# Opción 1: Eliminar archivo específico
kubectl delete -f 01-emptydir/pod-emptydir-basic.yaml

# Opción 2: Eliminar por directorio
kubectl delete -f 03-pvc-basico/

# Opción 3: Eliminar por label
kubectl delete all -l demo=rwx

# ⚠️ PVCs con política Retain:
# Requieren limpieza manual del PV y disco
```

---

## 📊 Guía Rápida de Decisiones

### ¿Qué tipo de volumen usar?

```
┌─────────────────────────────────┐
│ ¿Datos deben persistir          │
│ más allá del Pod?               │
└────────┬────────────────────────┘
         │
         ├─NO─→ emptyDir
         │     (Datos temporales)
         │
         └─SÍ─→ ¿Múltiples Pods necesitan acceso?
                │
                ├─NO──→ PVC con RWO (Azure Disk)
                │       (Base de datos, 1 réplica)
                │
                └─SÍ──→ PVC con RWX (Azure Files)
                        (WordPress, CMS, archivos compartidos)
```

### ¿Qué StorageClass usar?

```
┌─────────────────────────────────┐
│ ¿Cuál es la prioridad?          │
└────────┬────────────────────────┘
         │
         ├─COSTO───────→ managed-csi (Standard SSD)
         │
         ├─RENDIMIENTO─→ managed-csi-premium (Premium SSD)
         │
         └─COMPARTIDO──→ azurefile-csi (Azure Files)
```

### ¿Qué Reclaim Policy usar?

```
┌─────────────────────────────────┐
│ ¿Tipo de ambiente?              │
└────────┬────────────────────────┘
         │
         ├─PRODUCCIÓN──→ Retain
         │                (Proteger datos)
         │
         ├─DESARROLLO──→ Delete
         │                (Limpieza automática)
         │
         └─CI/CD───────→ Delete
                         (Recursos temporales)
```

---

## 🔗 Enlaces Relacionados

- [📖 Documentación Principal](../README.md)
- [🧪 Laboratorio 01 - Volúmenes Básicos](../laboratorios/lab-01-volumenes-basicos/)
- [🧪 Laboratorio 02 - PV/PVC Avanzado](../laboratorios/lab-02-pv-pvc-avanzado/)

---

## 📝 Notas Importantes

### Sobre Azure AKS

- **StorageClasses predefinidas** usan provisioner CSI (disk.csi.azure.com, file.csi.azure.com)
- **Azure Disk** es zonal: debe estar en misma zona que el nodo
- **Azure Files** puede ser multi-zona (compartido entre nodos)
- **Reclaim Policy por defecto**: Delete en todos los StorageClasses predefinidos

### Mejores Prácticas

1. ✅ **Usar PVC en lugar de volúmenes directos** (portabilidad)
2. ✅ **Labels y annotations** para organizar recursos
3. ✅ **Resource limits** en todos los contenedores
4. ✅ **Health checks** para aplicaciones stateful
5. ✅ **Backups externos** para datos críticos (no confiar solo en Retain)
6. ✅ **Monitorear PVs Released** (pueden generar costos)

### Troubleshooting

- **PVC Pending**: Ver eventos con `kubectl describe pvc <nombre>`
- **FailedAttachVolume**: Verificar zona del disco vs zona del nodo
- **Multi-Attach error**: Verificar Access Mode (probablemente necesitas RWX)
- **Disco no se eliminó**: Verificar Reclaim Policy del PV
- **Performance bajo**: Considerar Premium SSD o aumentar tamaño del disco

---

**¿Preguntas o problemas?** Consulta la [documentación principal](../README.md) o los [laboratorios prácticos](../laboratorios/).
