# Capítulo 32: Almacenamiento Persistente en AKS

Con Network Policies en su lugar, la comunicación entre Pods está controlada y la red del cluster es segura. Hemos asegurado quién puede hablar con quién — pero queda un problema crítico para cualquier aplicación real: ¿qué pasa con los datos cuando un Pod se reinicia?

Considera este escenario: despliegas una base de datos PostgreSQL en un Pod. Los usuarios empiezan a registrarse, hacer pedidos, guardar preferencias. El nodo falla por una actualización de kernel y el Pod se reprograma en otro nodo. Todo lo que estaba almacenado localmente en el contenedor desaparece — pedidos, cuentas de usuario, historial de transacciones. Los clientes pierden sus datos. El equipo de soporte recibe cientos de tickets. El incidente cuesta horas de trabajo y daño a la reputación. Este es el problema exacto que resuelve el almacenamiento persistente.

En Kubernetes los Volumes resuelven esto de forma genérica, pero en AKS disponemos de dos opciones cloud-native optimizadas para diferentes casos de uso: Azure Disk, que ofrece alto rendimiento para bases de datos con acceso de un solo Pod (ReadWriteOnce), y Azure Files, que permite que múltiples Pods compartan el mismo volumen simultáneamente (ReadWriteMany) mediante protocolos SMB o NFS.

Piensa en los volúmenes locales de los capítulos 17 y 18 como memorias USB: portátiles pero limitadas a una máquina. El almacenamiento en Azure es como una unidad de red en la nube: el Pod puede moverse de nodo en nodo y el disco lo sigue, o múltiples Pods en distintos nodos pueden acceder al mismo recurso compartido.

En este capítulo aprenderás las diferencias entre Azure Disk y Azure Files y cuándo usar cada uno, a trabajar con StorageClasses en AKS para aprovisionamiento dinámico, a crear PersistentVolumeClaims que se resuelven automáticamente, a configurar snapshots para backup de datos, y a conectar StatefulSets con almacenamiento persistente para bases de datos en producción.

---

## El Problema del Almacenamiento Efimero

### Que Pasa Cuando un Pod Pierde Sus Datos

En el capitulo 17 vimos que los contenedores tienen un sistema de archivos efimero: todo lo que se escribe dentro del contenedor vive en la capa de escritura del union filesystem, y esa capa desaparece en cuanto el contenedor se detiene o el Pod se elimina. Este comportamiento es correcto para aplicaciones sin estado, pero catastrofico para cualquier cosa que necesite persistir informacion entre reinicios.

El problema se vuelve mas grave en cloud que en servidores fisicos o virtuales tradicionales. En un servidor on-premises, si el proceso de base de datos falla, el directorio `/var/lib/postgresql/data` sigue existiendo en el disco fisico del servidor. El proceso se reinicia, encuentra sus datos intactos y continua. En Kubernetes sobre cloud, la situacion es completamente diferente por tres razones:

**1. Los nodos son fungibles.** AKS puede reemplazar un nodo por una VM diferente en cualquier momento: actualizaciones de kernel, scaling del node pool, fallos de hardware subyacente. El Pod se reprograma en otro nodo sin ninguna relacion con el anterior.

**2. Los discos efimeros de las VMs no siguen al Pod.** El almacenamiento local de una VM en Azure (`/dev/sda`, `/dev/sdb`) es efimero por definicion en la mayoria de las SKUs. Si la VM se reemplaza, ese disco desaparece.

**3. emptyDir se elimina con el Pod.** El tipo de volumen `emptyDir` que usamos en capitulos anteriores para compartir datos entre contenedores del mismo Pod dura exactamente lo que dura el Pod — ni un segundo mas.

Escenario real de fallo:

```
Lunes 09:00  → Despliegas PostgreSQL en Pod postgres-7d4f9b-xk2p1
Lunes 09:30  → 500 usuarios crean cuentas, 1.200 registros insertados
Lunes 14:00  → AKS actualiza el nodo worker-node-2 (actualizacion de seguridad)
Lunes 14:01  → Pod eliminado del nodo, reprogramado en worker-node-5
Lunes 14:01  → /var/lib/postgresql/data apunta a un emptyDir NUEVO y VACIO
Lunes 14:02  → PostgreSQL inicia con base de datos vacia
Lunes 14:03  → Los 500 usuarios intentan hacer login: "Invalid credentials"
Lunes 14:04  → El equipo de soporte recibe 500 tickets
```

Este no es un escenario hipotetico. Es exactamente lo que ocurre cuando se despliega una base de datos en Kubernetes sin almacenamiento persistente.

**Por que esto es MAS critico en cloud que on-premises:**

| Situacion | On-Premises | Cloud (AKS) |
|-----------|-------------|-------------|
| Fallo de proceso DB | Datos en disco local intactos | Datos en disco local intactos (si mismo nodo) |
| Reinicio del Pod en mismo nodo | Datos en disco local intactos | emptyDir eliminado, datos perdidos |
| Pod reprogramado en otro nodo | Requiere NFS/SAN configurado | emptyDir eliminado, datos perdidos |
| Actualizacion del nodo | Proceso manual, planificado | Automatico, transparente, sin datos |
| Escalado de infraestructura | Configuracion manual | Automatico, nuevas VMs sin datos |

La solucion en Kubernetes es desacoplar el almacenamiento del ciclo de vida del Pod usando PersistentVolumes. En AKS, esto se traduce en dos servicios de Azure especificamente disenados para este proposito: Azure Disk y Azure Files.

---

## Azure Disk vs Azure Files: Cuando Usar Cada Uno

La decision mas importante en almacenamiento de AKS es elegir entre Azure Disk y Azure Files. No es una decision trivial: elegir el tipo equivocado puede resultar en errores de montaje con multiples Pods, rendimiento insuficiente para bases de datos, o costes innecesariamente altos para cargas livianas.

### Tabla Comparativa Completa

| Caracteristica | Azure Disk | Azure Files |
|----------------|-----------|-------------|
| **Access Mode** | ReadWriteOnce (RWO) | ReadWriteMany (RWX) |
| **Protocolo** | Block storage (iSCSI/NBD) | SMB 3.0 / NFS 4.1 |
| **Acceso multi-Pod** | No — exactamente 1 Pod a la vez | Si — N Pods en N nodos simultaneamente |
| **IOPS maximos** | Hasta 160.000 (Ultra SSD) | Hasta 100.000 (Premium NFS) |
| **Latencia** | Sub-milisegundo (Premium/Ultra) | 1-10ms tipico |
| **Rendimiento sostenido** | Alto para escrituras aleatorias | Optimo para lecturas/escrituras secuenciales |
| **Tamano maximo** | 32 TiB | 100 TiB |
| **Backup nativo** | Snapshots de disco (instantaneas) | Azure Backup for Azure Files |
| **Cifrado en reposo** | SSE (Storage Service Encryption) + ADE | SMB encryption / NFS TLS |
| **Cifrado en transito** | N/A (block, dentro de Azure fabric) | SMB signing / NFS over TLS |
| **Costo relativo** | Menor por GB | Mayor por GB (especialmente Premium) |
| **CSI Driver** | `disk.csi.azure.com` | `file.csi.azure.com` |
| **Zona de disponibilidad** | Vinculado a una AZ (LRS) o multi-AZ (ZRS) | Multi-AZ nativo (GRS/ZRS disponible) |
| **Snapshot support** | VolumeSnapshot nativo en K8s | Via Azure Backup (no VolumeSnapshot) |
| **Casos de uso tipicos** | PostgreSQL, MySQL, MongoDB, etcd | CMS compartido, logs centralizados, assets estaticos, configuracion compartida |

### Arbol de Decision

Cuando necesitas decidir que tipo de almacenamiento usar, sigue este arbol:

```
¿Necesitas acceso desde multiples Pods simultaneamente?
│
├── SI → Azure Files (ReadWriteMany)
│   │
│   ├── ¿El workload requiere alto rendimiento (base de datos compartida,
│   │   procesamiento intensivo de archivos)?
│   │   └── SI → Azure Files Premium con protocolo NFS
│   │           StorageClass: azurefile-csi-premium
│   │           Protocolo: NFS 4.1 (mejor rendimiento que SMB)
│   │
│   └── ¿El workload es moderado (configuracion compartida, assets web,
│       logs centralizados)?
│       └── SI → Azure Files Standard con protocolo SMB
│               StorageClass: azurefile-csi
│               Protocolo: SMB 3.0 (compatible con Windows nodes)
│
└── NO → Azure Disk (ReadWriteOnce) — mejor rendimiento, menor costo
    │
    ├── ¿Es una base de datos de produccion?
    │   └── SI → Premium SSD (P-series)
    │           StorageClass: managed-csi-premium
    │           IOPS: hasta 20.000 (P30 y superiores)
    │           Latencia: <1ms
    │
    ├── ¿Es un entorno de desarrollo o testing?
    │   └── SI → Standard SSD (E-series)
    │           StorageClass: managed-csi (default en AKS)
    │           IOPS: hasta 6.000
    │           Latencia: single-digit ms
    │
    └── ¿Son datos frios, archivos de log historicos, backups?
        └── SI → Standard HDD (S-series)
                StorageClass: managed-csi con skuName: Standard_LRS
                IOPS: hasta 2.000
                Costo: el mas bajo de todos
```

### Ejemplos de Uso Concretos

**Usa Azure Disk cuando:**
- Despliegas PostgreSQL, MySQL, MongoDB, Redis con persistencia
- Tienes un StatefulSet con una replica por Pod
- Necesitas garantias de IOPS para SLAs de base de datos
- Tu aplicacion escribe datos de forma aleatoria y frecuente
- Necesitas snapshots consistentes del volumen

**Usa Azure Files cuando:**
- Tu Deployment tiene `replicas: 3` y todos los Pods necesitan leer/escribir en el mismo volumen
- Tienes un sistema de gestion de contenidos (WordPress, Drupal) con multiples replicas
- Los Pods de procesamiento de imagenes necesitan acceder al mismo directorio de assets
- Centralizas logs de multiples Pods en un directorio comun
- Compartes archivos de configuracion entre Pods en diferentes nodos

**Caso especial — ReadWriteOncePod (RWOP):**
Introducido en Kubernetes 1.22, `ReadWriteOncePod` garantiza que el volumen solo puede ser montado por exactamente un Pod en todo el cluster (no solo en un nodo). Es mas restrictivo que RWO y util cuando se necesita exclusividad absoluta:

```yaml
# ReadWriteOncePod: exclusividad absoluta en el cluster
spec:
  accessModes:
  - ReadWriteOncePod   # Solo este Pod especifico puede montar el volumen
```

---

## Conceptos de Almacenamiento en Kubernetes

### Tipos de Volúmenes

1. **Ephemeral**: Temporales, se eliminan con el Pod
2. **Persistent**: Sobreviven al ciclo de vida del Pod

### Componentes Principales

- **PersistentVolume (PV)**: Recurso de almacenamiento en el clúster
- **PersistentVolumeClaim (PVC)**: Solicitud de almacenamiento por un usuario
- **StorageClass**: Define tipos de almacenamiento disponibles

## Azure Storage en AKS

### Azure Disk

**Características:**
- **ReadWriteOnce**: Solo un Pod puede montar el disco
- **Rendimiento**: Standard HDD, Standard SSD, Premium SSD
- **Snapshots**: Soporte nativo
- **Encryption**: Azure Disk Encryption

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-disk-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: managed-premium
```

### Azure Files

**Características:**
- **ReadWriteMany**: Múltiples Pods pueden montar el volumen
- **Protocolos**: SMB y NFS
- **Compartido**: Entre múltiples nodos
- **Backup**: Azure Backup integration

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azure-files-pvc
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: azurefile
```

## StorageClasses en AKS en Profundidad

Las StorageClasses son la interfaz entre el mundo Kubernetes (PVCs) y el mundo Azure (APIs de storage). Cuando creas un PVC con un `storageClassName`, el CSI driver de AKS llama a la API de Azure para aprovisionar el recurso de almacenamiento correspondiente de forma automatica. Esto se llama **dynamic provisioning** y elimina la necesidad de crear PersistentVolumes manualmente.

### Listar y Explorar StorageClasses en AKS

```bash
# Ver todas las StorageClasses disponibles en un cluster AKS
kubectl get storageclass

# Salida esperada en un cluster AKS recien creado:
# NAME                    PROVISIONER          RECLAIMPOLICY  VOLUMEBINDINGMODE     ALLOWVOLUMEEXPANSION
# azurefile               file.csi.azure.com   Delete         Immediate             true
# azurefile-csi           file.csi.azure.com   Delete         Immediate             true
# azurefile-csi-premium   file.csi.azure.com   Delete         Immediate             true
# azurefile-premium       file.csi.azure.com   Delete         Immediate             true
# default (default)       disk.csi.azure.com   Delete         WaitForFirstConsumer  true
# managed                 disk.csi.azure.com   Delete         WaitForFirstConsumer  true
# managed-csi             disk.csi.azure.com   Delete         WaitForFirstConsumer  true
# managed-csi-premium     disk.csi.azure.com   Delete         WaitForFirstConsumer  true
# managed-premium         disk.csi.azure.com   Delete         WaitForFirstConsumer  true

# Ver los detalles completos de una StorageClass
kubectl describe storageclass managed-csi-premium

# Ver en YAML (util para copiar y personalizar)
kubectl get storageclass managed-csi -o yaml
```

### StorageClasses Incorporadas en AKS

**Para Azure Disk (block storage):**

```yaml
# StorageClass: managed-csi (la "default" en clusters AKS modernos)
# SKU: Standard SSD (E-series) — buen equilibrio costo/rendimiento
# Uso tipico: desarrollo, testing, workloads sin SLA estricto de IOPS
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-csi
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"  # Esta es la default
provisioner: disk.csi.azure.com
parameters:
  skuName: StandardSSD_LRS    # Standard SSD locally redundant
  kind: Managed
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer  # Espera al Pod antes de aprovisionar
```

```yaml
# StorageClass: managed-csi-premium
# SKU: Premium SSD (P-series) — alto rendimiento, baja latencia
# Uso tipico: bases de datos de produccion, etcd, workloads con SLA de IOPS
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-csi-premium
provisioner: disk.csi.azure.com
parameters:
  skuName: Premium_LRS         # Premium SSD locally redundant
  cachingmode: ReadOnly         # Cache de lectura para mejorar rendimiento
  kind: Managed
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

**Para Azure Files (shared storage):**

```yaml
# StorageClass: azurefile-csi
# Protocolo: SMB 3.0 — compatible con Linux y Windows
# Uso tipico: contenido compartido, assets web, logs centralizados
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azurefile-csi
provisioner: file.csi.azure.com
parameters:
  skuName: Standard_LRS        # Standard SMB share
mountOptions:
- mfsymlinks                   # Soporte para symlinks en SMB
- actimeo=30                   # Cache de atributos (mejora rendimiento)
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: Immediate   # Azure Files se aprovisiona inmediatamente
```

```yaml
# StorageClass: azurefile-csi-premium
# Protocolo: NFS 4.1 (premium) o SMB — mayor rendimiento que Standard
# Uso tipico: workloads con acceso compartido y requisitos de rendimiento
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azurefile-csi-premium
provisioner: file.csi.azure.com
parameters:
  skuName: Premium_LRS         # Premium FileShare
  protocol: nfs                # NFS 4.1 — mejor rendimiento que SMB
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: Immediate
```

### StorageClasses Personalizadas

En produccion frecuentemente necesitas StorageClasses con comportamiento especifico que las incorporadas no ofrecen. Estos son los patrones mas comunes:

**StorageClass con politica Retain (datos no se eliminan automaticamente):**

```yaml
# Uso: kubectl apply -f storageclass-retain.yaml
#
# IMPORTANTE: Con reclaimPolicy: Retain, cuando se elimina el PVC,
# el PV y el disco en Azure NO se eliminan. Requiere limpieza manual.
# Usar en produccion para datos criticos donde se prefiere precaucion.
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-csi-premium-retain
provisioner: disk.csi.azure.com
parameters:
  skuName: Premium_LRS
  cachingmode: ReadOnly
  kind: Managed
reclaimPolicy: Retain          # El PV queda en estado "Released", no se elimina
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

**StorageClass con Zone-Redundant Storage (ZRS) para alta disponibilidad:**

```yaml
# Uso: kubectl apply -f storageclass-zrs.yaml
#
# ZRS replica el disco en 3 zonas de disponibilidad de Azure.
# El Pod puede moverse entre nodos en distintas AZs sin necesidad
# de reattach manual. Costo ~20% superior a LRS.
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-csi-premium-zrs
provisioner: disk.csi.azure.com
parameters:
  skuName: Premium_ZRS         # Zone Redundant Storage — replica en 3 AZs
  cachingmode: None            # Sin cache (requerido para ZRS)
  kind: Managed
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

**StorageClass Ultra SSD para workloads de latencia extrema:**

```yaml
# Uso: kubectl apply -f storageclass-ultra.yaml
#
# Ultra SSD requiere que los nodos del node pool tengan
# la funcionalidad habilitada: az aks nodepool update --ultra-ssd-enabled
# IOPS configurables hasta 160.000, latencia sub-milisegundo.
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ultra-ssd
provisioner: disk.csi.azure.com
parameters:
  skuName: UltraSSD_LRS
  kind: Managed
  diskIOPSReadWrite: "10000"   # IOPS aprovisionados (configurable)
  diskMBpsReadWrite: "200"     # Throughput en MB/s (configurable)
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

### Volume Binding Modes

El campo `volumeBindingMode` controla CUANDO se aprovisiona el disco en Azure:

| Modo | Comportamiento | Cuando Usar |
|------|---------------|-------------|
| `Immediate` | El disco se crea en Azure en cuanto se crea el PVC, antes de que el Pod exista | Azure Files, cuando necesitas pre-provisionar storage |
| `WaitForFirstConsumer` | El disco se crea cuando el Pod que usa el PVC se programa en un nodo | Azure Disk (recomendado) — garantiza que el disco se crea en la misma AZ que el nodo |

El modo `WaitForFirstConsumer` es critico para Azure Disk en clusters multi-zona. Si usaras `Immediate`, el disco podria crearse en la AZ-1 pero el Pod podria programarse en la AZ-2, causando un error de montaje porque Azure Disk LRS solo puede montarse en la misma AZ donde existe.

### Expansion de Volumenes

La mayoria de las StorageClasses en AKS tienen `allowVolumeExpansion: true`, lo que permite aumentar el tamano de un PVC sin recrearlo:

```bash
# Verificar que la StorageClass soporta expansion
kubectl get storageclass managed-csi-premium -o jsonpath='{.allowVolumeExpansion}'
# Salida: true

# Editar el PVC para aumentar su tamano (de 20Gi a 40Gi)
kubectl patch pvc postgres-storage-database-statefulset-0 \
  -n desarrollo \
  -p '{"spec":{"resources":{"requests":{"storage":"40Gi"}}}}'

# Monitorear el proceso de expansion
kubectl get pvc postgres-storage-database-statefulset-0 -n desarrollo -w
# NAME                                    STATUS   VOLUME    CAPACITY   ACCESS MODES
# postgres-storage-database-statefulset-0 Bound    pvc-xxx   20Gi       RWO
# postgres-storage-database-statefulset-0 Bound    pvc-xxx   40Gi       RWO   # <-- expansion completada

# Verificar en el Pod que el disco expandido es visible
kubectl exec -n desarrollo database-statefulset-0 -- df -h /var/lib/postgresql/data
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sdc        40G   2.1G  38G   6%  /var/lib/postgresql/data
```

Nota: Para Azure Disk, la expansion en linea (sin desmontar) requiere Kubernetes 1.24+ y el CSI driver actualizado. En versiones anteriores, el Pod debe reiniciarse para que el sistema de archivos reconozca el nuevo tamano.

---

## Flujo de Aprovisionamiento Dinamico

Entender el flujo completo del dynamic provisioning ayuda a diagnosticar problemas cuando los PVCs quedan en estado Pending o cuando el montaje falla.

### Diagrama del Flujo Completo

```
Usuario aplica PVC
        │
        ▼
kubectl apply -f pvc.yaml
        │
        ▼
API Server almacena el PVC con status: Pending
        │
        ▼
kube-controller-manager detecta PVC sin PV asociado
        │
        ▼
Identifica StorageClass referenciada en el PVC
        │
        ▼
(Si WaitForFirstConsumer) Espera a que el scheduler asigne un Pod a un nodo
        │
        ▼
CSI External Provisioner recibe la solicitud
        │
        ▼
CSI Driver (disk.csi.azure.com / file.csi.azure.com)
llama a la Azure REST API
        │
        ▼
Azure crea el Managed Disk o FileShare en el Resource Group del cluster
(tipicamente MC_<rg>_<cluster>_<region>)
        │
        ▼
CSI Driver crea el objeto PersistentVolume en Kubernetes
con los detalles del recurso Azure creado
        │
        ▼
kube-controller-manager vincula PVC al PV
Status PVC: Pending → Bound
        │
        ▼
kubelet en el nodo donde esta el Pod
recibe instruccion de montar el volumen
        │
        ▼
CSI Node Driver hace el attach del disco (Azure API: attach disk to VM)
        │
        ▼
kubelet hace el mount del disco en el directorio del Pod
(/var/lib/kubelet/pods/<pod-uid>/volumes/...)
        │
        ▼
Pod puede leer/escribir en el volumeMount
```

### Ciclo de Vida del PersistentVolume

Un PV pasa por estos estados durante su vida:

```
Creacion del PVC
       │
       ▼
  [Provisioning]
  CSI aprovisiona
  recurso en Azure
       │
       ▼
   [Available]
   PV existe pero
   no esta vinculado
       │
       ▼
    [Bound]
    PVC ↔ PV
    vinculados
    Pod usando datos
       │
       ▼
   [Released]
   PVC eliminado
   PV liberado pero
   contiene datos
       │
   ┌───┴──────────┐
   │              │
   ▼              ▼
[Reclaimed]   [Retained]
(policy:Delete) (policy:Retain)
Disco eliminado  PV y disco
en Azure         permanecen
                 Requiere
                 limpieza manual
```

### Reclaim Policies en Detalle

**Delete (default en la mayoria de StorageClasses):**

```bash
# Cuando eliminas el PVC, el PV y el disco Azure se eliminan automaticamente
kubectl delete pvc mi-pvc -n production
# Azure Managed Disk: ELIMINADO del Resource Group
# PRECAUCION: Los datos se pierden permanentemente
```

**Retain — para datos criticos en produccion:**

```bash
# El PVC se elimina pero el PV queda en estado Released
kubectl delete pvc mi-pvc-critico -n production

# El PV aun existe con status Released
kubectl get pv
# NAME      CAPACITY  STATUS    CLAIM
# pv-xxxxx  100Gi     Released  production/mi-pvc-critico

# Para reutilizar el PV, debes eliminar el campo claimRef manualmente
kubectl patch pv pv-xxxxx -p '{"spec":{"claimRef":null}}'
# El PV vuelve a Available y puede ser reclamado por un nuevo PVC

# O recuperar los datos directamente del disco en Azure antes de eliminarlo
# az disk list --resource-group MC_... --query "[?diskState=='Unattached']"
```

---

## Snapshots y Backup de Volumenes

Los snapshots permiten capturar el estado de un volumen en un momento especifico, sin necesidad de detener la aplicacion (aunque para bases de datos se recomienda flush previo). Son esenciales para cualquier estrategia de recuperacion ante desastres.

### Componentes del Sistema de Snapshots

```
VolumeSnapshotClass  →  Define el driver y las politicas
       │
       ▼
VolumeSnapshot       →  Solicitud de captura (como un PVC pero para snapshots)
       │
       ▼
VolumeSnapshotContent →  El snapshot real en Azure (como un PV pero para snapshots)
```

### Verificar que el CSI Snapshot Controller esta Instalado

```bash
# El snapshot controller debe estar instalado en el cluster
kubectl get crds | grep snapshot
# volumesnapshotclasses.snapshot.storage.k8s.io
# volumesnapshotcontents.snapshot.storage.k8s.io
# volumesnapshots.snapshot.storage.k8s.io

# Ver VolumeSnapshotClasses disponibles en AKS
kubectl get volumesnapshotclass
# NAME                    DRIVER                  DELETIONPOLICY   AGE
# csi-azuredisk-vsc       disk.csi.azure.com      Delete           10d
```

### Crear un Snapshot Manual

```yaml
# Uso: kubectl apply -f volumesnapshot-postgres.yaml
#
# Crea un snapshot del PVC de PostgreSQL.
# El snapshot se almacena como un Azure Managed Disk Snapshot
# en el Resource Group del cluster.
#
# PRE-REQUISITO: Para consistencia de datos en PostgreSQL,
# ejecutar CHECKPOINT; en psql antes de crear el snapshot.
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: postgres-snapshot-manual
  namespace: desarrollo
  labels:
    app: postgres
    backup-type: manual
    created-by: admin
spec:
  volumeSnapshotClassName: csi-azuredisk-vsc
  source:
    persistentVolumeClaimName: postgres-storage-database-statefulset-0
```

```bash
# Aplicar el snapshot
kubectl apply -f volumesnapshot-postgres.yaml

# Monitorear el estado del snapshot
kubectl get volumesnapshot -n desarrollo -w
# NAME                     READYTOUSE   SOURCEPVC                                   SNAPSHOTCONTENT       AGE
# postgres-snapshot-manual false        postgres-storage-database-statefulset-0                           5s
# postgres-snapshot-manual true         postgres-storage-database-statefulset-0     snapcontent-xxxxxxxx  30s

# Ver detalles del snapshot (incluye el ID del snapshot en Azure)
kubectl describe volumesnapshot postgres-snapshot-manual -n desarrollo
# Status:
#   Bound Volume Snapshot Content Name: snapcontent-xxxxxxxx
#   Creation Time: 2024-01-15T10:30:00Z
#   Ready To Use: true
#   Restore Size: 20Gi
```

### Restaurar un Volumen desde Snapshot

```yaml
# Uso: kubectl apply -f pvc-from-snapshot.yaml
#
# Crea un nuevo PVC a partir de un snapshot existente.
# Esto crea un nuevo Azure Managed Disk con los datos del snapshot.
# El PVC original y el nuevo coexisten — los datos no se sobreescriben.
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-restored-pvc
  namespace: desarrollo
  labels:
    app: postgres
    restore-source: postgres-snapshot-manual
    restore-date: "2024-01-15"
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi             # Debe ser >= al tamano del snapshot
  storageClassName: managed-csi-premium
  dataSource:
    name: postgres-snapshot-manual         # Nombre del VolumeSnapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
```

```bash
# Aplicar el PVC restaurado
kubectl apply -f pvc-from-snapshot.yaml

# Verificar que el PVC se vincula correctamente
kubectl get pvc postgres-restored-pvc -n desarrollo
# NAME                     STATUS   VOLUME    CAPACITY   ACCESS MODES
# postgres-restored-pvc    Bound    pvc-yyy   20Gi       RWO
```

### Backup Automatico con CronJob

Para automatizar los snapshots diarios sin herramientas externas:

```yaml
# Uso: kubectl apply -f cronjob-snapshot.yaml
#
# Crea snapshots diarios del volumen de PostgreSQL a las 02:00.
# Requiere un ServiceAccount con permisos para crear VolumeSnapshots.
# Los snapshots se nombran con la fecha para facilitar identificacion.
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-daily-snapshot
  namespace: desarrollo
spec:
  schedule: "0 2 * * *"           # Cada dia a las 02:00 UTC
  successfulJobsHistoryLimit: 7   # Mantener logs de los ultimos 7 snapshots
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: snapshot-manager  # SA con permisos en VolumeSnapshots
          restartPolicy: OnFailure
          containers:
          - name: snapshot-creator
            image: bitnami/kubectl:latest
            command:
            - /bin/bash
            - -c
            - |
              DATE=$(date +%Y%m%d-%H%M)
              cat <<EOF | kubectl apply -f -
              apiVersion: snapshot.storage.k8s.io/v1
              kind: VolumeSnapshot
              metadata:
                name: postgres-auto-${DATE}
                namespace: desarrollo
                labels:
                  backup-type: automated
                  backup-date: "${DATE}"
              spec:
                volumeSnapshotClassName: csi-azuredisk-vsc
                source:
                  persistentVolumeClaimName: postgres-storage-database-statefulset-0
              EOF
              echo "Snapshot postgres-auto-${DATE} creado exitosamente"
            resources:
              requests:
                memory: "32Mi"
                cpu: "50m"
              limits:
                memory: "64Mi"
                cpu: "100m"
---
# ServiceAccount para el CronJob
apiVersion: v1
kind: ServiceAccount
metadata:
  name: snapshot-manager
  namespace: desarrollo
---
# ClusterRole con permisos minimos necesarios
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: volumesnapshot-creator
rules:
- apiGroups: ["snapshot.storage.k8s.io"]
  resources: ["volumesnapshots"]
  verbs: ["create", "get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: snapshot-manager-binding
subjects:
- kind: ServiceAccount
  name: snapshot-manager
  namespace: desarrollo
roleRef:
  kind: ClusterRole
  name: volumesnapshot-creator
  apiGroup: rbac.authorization.k8s.io
```

### Azure Backup for AKS

Para entornos de produccion, Azure Backup ofrece integracion nativa con AKS que va mas alla de los VolumeSnapshots:

```bash
# Habilitar Azure Backup for AKS (via Azure CLI)
# Requiere: Backup vault en el mismo resource group o region

# 1. Registrar el proveedor de backup
az provider register --namespace Microsoft.DataProtection

# 2. Crear el Backup Vault
az dataprotection backup-vault create \
  --resource-group rg-aks-production \
  --vault-name aks-backup-vault \
  --location eastus \
  --type SystemAssigned \
  --storage-settings datastore-type="VaultStore" type="LocallyRedundant"

# 3. Instalar la extension de backup en AKS
az k8s-extension create \
  --name azure-aks-backup \
  --extension-type Microsoft.DataProtection.Kubernetes \
  --scope cluster \
  --cluster-type managedClusters \
  --cluster-name aks-production \
  --resource-group rg-aks-production \
  --release-train stable \
  --configuration-settings blobContainer=<container> \
    storageAccount=<account> \
    storageAccountResourceGroup=<rg> \
    storageAccountSubscriptionId=<sub-id>

# 4. Crear una politica de backup (GUI recomendada para produccion)
# La politica define: frecuencia, retencion, que namespaces incluir
```

Azure Backup for AKS permite:
- Backup de recursos Kubernetes (Deployments, ConfigMaps, Secrets) ademas de volumenes
- Restauracion selectiva por namespace
- Retencion configurable (dias, semanas, meses)
- Backup cross-region para disaster recovery

---

## StatefulSets con Almacenamiento Persistente

Las bases de datos y otros workloads con estado tienen requisitos que los Deployments no pueden satisfacer: identidad de red estable, orden de arranque/parada garantizado, y — crucialmente — almacenamiento persistente que siga al Pod especifico, no al Deployment en general.

### Por Que los Deployments No Son Suficientes para Bases de Datos

Imagina desplegar PostgreSQL con un Deployment con `replicas: 2`:

```
Problema con Deployment:

  postgres-7d4f9b-xk2p1  →  PVC: postgres-data  →  Disco Azure (escritura)
  postgres-7d4f9b-m3n4p  →  PVC: postgres-data  →  MISMO Disco Azure (escritura)

  Resultado: Dos instancias de PostgreSQL escribiendo en el mismo disco
             → Corrupcion de datos garantizada
             → PostgreSQL entrara en modo de recuperacion de emergencia
```

Con un StatefulSet, cada replica obtiene su PROPIO volumen:

```
Solucion con StatefulSet:

  database-statefulset-0  →  PVC: postgres-storage-database-statefulset-0  →  Disco propio
  database-statefulset-1  →  PVC: postgres-storage-database-statefulset-1  →  Disco propio
  database-statefulset-2  →  PVC: postgres-storage-database-statefulset-2  →  Disco propio

  Resultado: Cada replica de PostgreSQL tiene su propio disco dedicado
             Compatible con replicacion nativa de PostgreSQL (primario + replicas)
```

### volumeClaimTemplates Explicado

La clave de los StatefulSets para storage es el campo `volumeClaimTemplates`. Es una PLANTILLA — no un PVC — que el StatefulSet usa para crear un PVC unico para cada replica:

```yaml
# Fragmento de un StatefulSet con volumeClaimTemplates
spec:
  replicas: 3
  serviceName: postgres-headless

  # ... template del Pod ...

  volumeClaimTemplates:              # <-- PLANTILLA, no un PVC directamente
  - metadata:
      name: postgres-storage         # Este nombre se usa para construir el nombre del PVC
      labels:
        app: postgres
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: managed-csi-premium
      resources:
        requests:
          storage: 20Gi

# Resultado: Kubernetes crea automaticamente:
#   PVC: postgres-storage-database-statefulset-0  (para el Pod -0)
#   PVC: postgres-storage-database-statefulset-1  (para el Pod -1)
#   PVC: postgres-storage-database-statefulset-2  (para el Pod -2)
```

### Comportamiento al Escalar un StatefulSet

```bash
# StatefulSet actualmente con 1 replica
kubectl get statefulset database-statefulset -n desarrollo
# NAME                    READY   AGE
# database-statefulset    1/1     5d

kubectl get pvc -n desarrollo
# NAME                                      STATUS   VOLUME     CAPACITY
# postgres-storage-database-statefulset-0  Bound    pvc-aaa    20Gi

# Escalar a 3 replicas
kubectl scale statefulset database-statefulset --replicas=3 -n desarrollo

# StatefulSet crea los Pods y PVCs en orden estricto: -1 antes de -2
# (espera a que -1 este Ready antes de crear -2)

kubectl get pods -n desarrollo -w
# database-statefulset-0   Running   5d
# database-statefulset-1   Pending   5s   <- creandose
# database-statefulset-1   Running   35s  <- listo
# database-statefulset-2   Pending   36s  <- ahora crea el -2

kubectl get pvc -n desarrollo
# NAME                                      STATUS   CAPACITY
# postgres-storage-database-statefulset-0  Bound    20Gi
# postgres-storage-database-statefulset-1  Bound    20Gi   <- nuevo
# postgres-storage-database-statefulset-2  Bound    20Gi   <- nuevo
```

### Comportamiento al Eliminar un StatefulSet

Este es uno de los puntos mas importantes — y mas contra-intuitivos — del almacenamiento en StatefulSets:

```bash
# Eliminar el StatefulSet
kubectl delete statefulset database-statefulset -n desarrollo

# Los Pods se eliminan... pero los PVCs NO
kubectl get pods -n desarrollo -l app=database
# (vacio - los pods fueron eliminados)

kubectl get pvc -n desarrollo
# NAME                                      STATUS   CAPACITY
# postgres-storage-database-statefulset-0  Bound    20Gi   <- AUN EXISTE
# postgres-storage-database-statefulset-1  Bound    20Gi   <- AUN EXISTE
# postgres-storage-database-statefulset-2  Bound    20Gi   <- AUN EXISTE

# ESTO ES INTENCIONAL: Kubernetes protege los datos ante eliminaciones accidentales
# Si vuelves a crear el StatefulSet con el mismo nombre, los Pods se reconectaran
# automaticamente a sus PVCs existentes (los datos persisten)

# Para eliminar TAMBIEN los datos (eliminar PVCs manualmente):
kubectl delete pvc postgres-storage-database-statefulset-{0,1,2} -n desarrollo
# ATENCION: Esta operacion es irreversible si reclaimPolicy es Delete
```

Esta proteccion de datos en los StatefulSets es deliberada. Considera un escenario de error humano: un ingeniero ejecuta `kubectl delete statefulset postgres` creyendo que solo eliminara el Deployment. Si los PVCs se eliminaran automaticamente, la base de datos de produccion desapareceria. Kubernetes protege los datos exigiendo la eliminacion manual de los PVCs.

---

## Laboratorio 3.3: Configurar Almacenamiento Persistente

### Paso 1: Azure Disk con StatefulSet

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database-statefulset
  namespace: desarrollo
spec:
  serviceName: database-headless
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: myapp
        - name: POSTGRES_USER
          value: appuser
        - name: POSTGRES_PASSWORD
          value: secretpassword
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
          name: postgres
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: managed-premium
      resources:
        requests:
          storage: 20Gi
---
apiVersion: v1
kind: Service
metadata:
  name: database-headless
  namespace: desarrollo
spec:
  clusterIP: None
  selector:
    app: database
  ports:
  - port: 5432
    targetPort: 5432
EOF

# Verificar StatefulSet y PVC
kubectl get statefulset -n desarrollo
kubectl get pvc -n desarrollo
kubectl get pv
```

### Paso 2: Azure Files Compartido

```bash
# Crear PVC para Azure Files
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-storage
  namespace: desarrollo
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: azurefile
EOF

# Deployment que usa Azure Files
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: file-share-app
  namespace: desarrollo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: file-share
  template:
    metadata:
      labels:
        app: file-share
    spec:
      containers:
      - name: app
        image: nginx:1.21
        volumeMounts:
        - name: shared-data
          mountPath: /usr/share/nginx/html
        - name: logs
          mountPath: /var/log/nginx
      volumes:
      - name: shared-data
        persistentVolumeClaim:
          claimName: shared-storage
      - name: logs
        persistentVolumeClaim:
          claimName: shared-storage
EOF

# Verificar que múltiples pods comparten el volumen
kubectl get pods -n desarrollo -l app=file-share
kubectl exec -n desarrollo deployment/file-share-app -- ls -la /usr/share/nginx/html
```

### Paso 3: Probar Persistencia

```bash
# Escribir datos en el StatefulSet
kubectl exec -n desarrollo database-statefulset-0 -- psql -U appuser -d myapp -c "CREATE TABLE test (id SERIAL PRIMARY KEY, data TEXT);"
kubectl exec -n desarrollo database-statefulset-0 -- psql -U appuser -d myapp -c "INSERT INTO test (data) VALUES ('Datos persistentes');"

# Eliminar pod para probar persistencia
kubectl delete pod database-statefulset-0 -n desarrollo

# Esperar a que se recree y verificar datos
kubectl wait --for=condition=ready pod database-statefulset-0 -n desarrollo --timeout=60s
kubectl exec -n desarrollo database-statefulset-0 -- psql -U appuser -d myapp -c "SELECT * FROM test;"
```

### Paso 4: Snapshots de Volúmenes

```bash
# Crear VolumeSnapshot
cat << 'EOF' | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: postgres-snapshot
  namespace: desarrollo
spec:
  volumeSnapshotClassName: csi-azuredisk-vsc
  source:
    persistentVolumeClaimName: postgres-storage-database-statefulset-0
EOF

# Verificar snapshot
kubectl get volumesnapshot -n desarrollo
kubectl describe volumesnapshot postgres-snapshot -n desarrollo

# Restaurar desde snapshot
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restored-postgres-pvc
  namespace: desarrollo
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: managed-premium
  dataSource:
    name: postgres-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
EOF
```

---

## Troubleshooting de Almacenamiento en AKS

El almacenamiento es una de las areas mas frecuentes de problemas en clusters de AKS. Los errores pueden surgir en cualquier punto del flujo: durante el aprovisionamiento del PVC, durante el montaje del volumen, durante la operacion, o en actualizaciones. Esta seccion cubre los 6 escenarios mas comunes con diagnostico y solucion paso a paso.

---

### Escenario 1: PVC Atascado en Estado Pending

**Sintomas:**

```bash
kubectl get pvc -n mi-namespace
# NAME          STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS    AGE
# mi-pvc        Pending                                       managed-csi     10m

kubectl describe pvc mi-pvc -n mi-namespace
# Events:
#   Warning  ProvisioningFailed  ... no volume plugin matched
```

**Causas posibles y diagnostico:**

```bash
# Causa 1: StorageClass no existe o tiene nombre incorrecto
kubectl get storageclass
# Compara el nombre en el PVC con las StorageClasses disponibles
# ERROR comun: usar "managed-premium" en lugar de "managed-csi-premium"

# Verificar que la StorageClass referenciada existe
kubectl get storageclass managed-csi-premium
# Error from server (NotFound): storageclasses.storage.k8s.io "managed-csi-premium" not found
# SOLUCION: Corregir el storageClassName en el PVC

# Causa 2: El CSI driver no esta instalado o no funciona
kubectl get pods -n kube-system | grep csi
# csi-azuredisk-controller-xxx   Running
# csi-azuredisk-node-xxx         Running  (debe haber uno por nodo)
# Si algun pod no esta Running, hay un problema con el driver

# Revisar logs del CSI driver
kubectl logs -n kube-system deployment/csi-azuredisk-controller -c azuredisk
# Buscar errores de autenticacion con Azure API (MSI/service principal)

# Causa 3: Quota de discos agotada en la suscripcion Azure
az vm list-usage --location eastus --query "[?name.value=='Disks']"
# Si currentValue >= limit, la suscripcion no puede crear mas discos
# SOLUCION: Solicitar aumento de quota en Azure Portal

# Causa 4: No hay suficientes IPs disponibles en la subnet del nodo
# (Azure Files con Private Endpoint)
az network vnet subnet list --resource-group MC_... --vnet-name aks-vnet \
  --query "[].{Name:name, UsedIPs:ipConfigurations}" -o table
```

**Solucion rapida:**

```bash
# Verificar el evento exacto del problema
kubectl describe pvc <nombre> -n <namespace> | grep -A 5 "Events:"

# Si es StorageClass incorrecta, eliminar y recrear con el nombre correcto
kubectl delete pvc mi-pvc -n mi-namespace
# Editar el manifiesto con el storageClassName correcto
kubectl apply -f pvc-corregido.yaml
```

---

### Escenario 2: Error de Montaje — Disco ya Asociado a Otro Nodo

**Sintomas:**

```bash
kubectl describe pod mi-pod -n mi-namespace
# Events:
#   Warning  FailedMount  ... Multi-Attach error for volume "pvc-xxx"
#             Volume is already used by pod(s) otro-pod

kubectl get pod mi-pod -n mi-namespace
# NAME      READY   STATUS              RESTARTS
# mi-pod    0/1     ContainerCreating   0   <- atascado por minutos
```

**Causa:**

Este error ocurre con Azure Disk (RWO) cuando el scheduler intenta montar el mismo disco en dos nodos simultaneamente. Sucede tipicamente cuando:

- Un Pod nuevo se programa antes de que el Pod antiguo (en otro nodo) haya liberado completamente el disco
- El nodo anterior fallo abruptamente y el disco sigue "attached" en Azure aunque el Pod no existe

**Diagnostico y solucion:**

```bash
# Identificar donde esta montado el disco actualmente
kubectl get volumeattachment
# NAME                                                 ATTACHER                  PV          NODE              ATTACHED
# csi-xxxxxxxxx                                        disk.csi.azure.com        pvc-yyy     worker-node-1     true

# Verificar si el Pod del nodo antiguo aun existe
kubectl get pods --all-namespaces --field-selector spec.nodeName=worker-node-1

# Opcion 1: Si el Pod anterior existe, eliminarlo para liberar el disco
kubectl delete pod pod-anterior -n mi-namespace --force --grace-period=0

# Opcion 2: Eliminar el VolumeAttachment manualmente (fuerza el detach)
kubectl delete volumeattachment csi-xxxxxxxxx
# PRECAUCION: Solo hacer si el nodo realmente fallo o fue eliminado

# Opcion 3: Si el nodo esta en NotReady, hacer taint/cordon y esperar al timeout
# Kubernetes detectara el nodo como muerto tras ~5 minutos y liberara los discos
kubectl cordon worker-node-1
# Esperar node-monitor-grace-period (default 40s) + pod-eviction-timeout (default 5min)
```

**Prevencion:**

```bash
# Usar terminationGracePeriodSeconds corto para bases de datos que aceptan SIGTERM
spec:
  terminationGracePeriodSeconds: 30   # Por defecto es 30s, ajustar segun la app

# Configurar el node-monitor-grace-period si los detaches son lentos
# (Esta configuracion es a nivel del kube-controller-manager, no editable en AKS managed)
```

---

### Escenario 3: Disco Lleno — Expandir un PVC

**Sintomas:**

```bash
# La aplicacion empieza a fallar con errores de "no space left on device"
kubectl exec -n produccion postgres-0 -- df -h /var/lib/postgresql/data
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sdc        20G   19G  500M  98%  /var/lib/postgresql/data

kubectl logs -n produccion postgres-0 | tail -20
# FATAL:  could not write to file "pg_wal/00000001000000000000001": No space left on device
```

**Solucion paso a paso:**

```bash
# Paso 1: Verificar que la StorageClass permite expansion
kubectl get storageclass managed-csi-premium -o jsonpath='{.allowVolumeExpansion}'
# Salida: true

# Paso 2: Editar el PVC para aumentar el storage request
kubectl patch pvc postgres-storage-postgres-0 \
  -n produccion \
  -p '{"spec":{"resources":{"requests":{"storage":"50Gi"}}}}'
# persistentvolumeclaim/postgres-storage-postgres-0 patched

# Paso 3: Monitorear la expansion
kubectl get pvc postgres-storage-postgres-0 -n produccion -w
# NAME                         STATUS   VOLUME     CAPACITY   ACCESS MODES   STORAGECLASS
# postgres-storage-postgres-0  Bound    pvc-zzz    20Gi       RWO            managed-csi-premium
# postgres-storage-postgres-0  Bound    pvc-zzz    50Gi       RWO            managed-csi-premium

# Paso 4: Verificar que el filesystem se expandio (puede requerir reinicio del Pod)
kubectl exec -n produccion postgres-0 -- df -h /var/lib/postgresql/data
# Si el tamano no cambio, el filesystem necesita ser expandido dentro del Pod:

# Paso 5: Si el filesystem no se expandio automaticamente, reiniciar el Pod
kubectl delete pod postgres-0 -n produccion
# El StatefulSet recreara el Pod y el kubelet expandira el filesystem al montar

# Verificacion final
kubectl exec -n produccion postgres-0 -- df -h /var/lib/postgresql/data
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sdc        50G   19G  31G   38%  /var/lib/postgresql/data
```

---

### Escenario 4: I/O Lento — SKU Incorrecto para la Carga de Trabajo

**Sintomas:**

```bash
# Queries PostgreSQL que deberian tomar milisegundos tardan segundos
kubectl exec -n produccion postgres-0 -- psql -U postgres -c "\timing on" \
  -c "SELECT count(*) FROM orders;"
# Time: 8543.291 ms   <- deberia ser <100ms para esta query con indice

# Altas latencias de I/O visibles en las metricas
kubectl top pods -n produccion
# NAME         CPU(cores)   MEMORY(bytes)
# postgres-0   150m         1Gi            # CPU y memoria OK

# Verificar el tipo de disco actual
kubectl get pvc postgres-storage-postgres-0 -n produccion -o jsonpath='{.spec.storageClassName}'
# managed-csi   <- Standard SSD! Para una DB de produccion esto es insuficiente
```

**Diagnostico:**

```bash
# Ver los IOPS actuales del disco (requiere metrics server o Azure Monitor)
# En Azure Portal: recurso Managed Disk -> Metricas -> Disk IOPS Consumed Percentage
# Si esta consistentemente >80%, el disco esta saturado

# Alternativa: medir I/O directamente en el Pod
kubectl exec -n produccion postgres-0 -- dd if=/dev/zero of=/var/lib/postgresql/data/testfile \
  bs=4k count=10000 oflag=direct
# 10000+0 records in / 10000+0 records out
# 40960000 bytes (41 MB, 39 MiB) copied, 8.2 s, 5.0 MB/s   <- muy lento para Premium SSD
```

**Solucion — Migrar a una StorageClass de mayor rendimiento:**

```bash
# No se puede cambiar la StorageClass de un PVC existente directamente.
# El proceso requiere: snapshot -> nuevo PVC con StorageClass correcta -> migrar

# Paso 1: Crear snapshot del volumen actual
kubectl apply -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: postgres-migration-snapshot
  namespace: produccion
spec:
  volumeSnapshotClassName: csi-azuredisk-vsc
  source:
    persistentVolumeClaimName: postgres-storage-postgres-0
EOF

# Paso 2: Esperar a que el snapshot este listo
kubectl wait volumesnapshot/postgres-migration-snapshot \
  -n produccion --for=jsonpath='{.status.readyToUse}'=true --timeout=300s

# Paso 3: Crear nuevo PVC con Premium StorageClass desde el snapshot
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-storage-premium
  namespace: produccion
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: managed-csi-premium   # <-- StorageClass correcta
  resources:
    requests:
      storage: 50Gi
  dataSource:
    name: postgres-migration-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
EOF

# Paso 4: Actualizar el StatefulSet para usar el nuevo PVC
# (requiere modificar el manifest y hacer rolling restart)
```

**Prevencion:**

Usa siempre `managed-csi-premium` para bases de datos de produccion. La diferencia de costo entre Standard SSD y Premium SSD es pequeña comparada con el impacto de rendimiento en una base de datos de produccion.

---

### Escenario 5: Pod Atascado en ContainerCreating — Disco en Zona Diferente

**Sintomas:**

```bash
kubectl get pod postgres-0 -n produccion
# NAME         READY   STATUS              RESTARTS   AGE
# postgres-0   0/1     ContainerCreating   0          15m

kubectl describe pod postgres-0 -n produccion
# Events:
#   Warning  FailedAttachVolume  ... Disk pvc-xxx is not in the same zone as node
#   Warning  FailedMount         ... Unable to attach or mount volumes
```

**Causa:**

El disco Azure (LRS) fue creado en la zona `eastus-1` pero el nodo disponible esta en `eastus-2`. Los discos LRS (Locally Redundant Storage) solo pueden montarse desde VMs en la misma zona de disponibilidad.

**Diagnostico:**

```bash
# Ver en que zona esta el nodo
kubectl get node worker-node-3 -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'
# eastus-2

# Ver en que zona esta el disco
kubectl get pv pvc-xxx -o jsonpath='{.spec.nodeAffinity}'
# {"required":{"nodeSelectorTerms":[{"matchExpressions":[{
#   "key":"topology.kubernetes.io/zone",
#   "operator":"In",
#   "values":["eastus-1"]   <- Zona del disco, diferente al nodo
# }]}]}}
```

**Soluciones:**

```bash
# Opcion 1 (recomendada): Usar StorageClass con ZRS en lugar de LRS
# ZRS replica el disco en 3 zonas, puede montarse en cualquier nodo del cluster

# Opcion 2: Forzar el Pod al nodo en la zona correcta con nodeAffinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: topology.kubernetes.io/zone
            operator: In
            values: ["eastus-1"]   # Misma zona que el disco

# Opcion 3: Si el cluster tiene volumeBindingMode: WaitForFirstConsumer (recomendado),
# el disco SE CREA en la zona del nodo donde se programa el Pod.
# Asegurarse de que la StorageClass usa WaitForFirstConsumer.
kubectl get storageclass managed-csi -o jsonpath='{.volumeBindingMode}'
# WaitForFirstConsumer  <- correcto

# Si era Immediate, cambiar a WaitForFirstConsumer en una nueva StorageClass
# y migrar los datos (proceso similar al Escenario 4)
```

---

### Escenario 6: Azure Files — Errores de Permisos con SMB

**Sintomas:**

```bash
kubectl exec -n mi-app web-pod-xxx -- ls /mnt/shared
# ls: cannot open directory '/mnt/shared': Permission denied

kubectl logs -n mi-app web-pod-xxx
# Error: EACCES: permission denied, open '/mnt/shared/config.json'
```

**Causa:**

SMB monta todos los archivos con el UID/GID del proceso que realiza el montaje (normalmente root/0:0). Si el contenedor corre como un usuario no-root, no puede acceder a los archivos.

**Diagnostico:**

```bash
# Ver con que usuario corre el contenedor
kubectl exec -n mi-app web-pod-xxx -- id
# uid=1000(appuser) gid=1000(appgroup) groups=1000(appgroup)

# Ver los permisos actuales en el mount point
kubectl exec -n mi-app web-pod-xxx -- ls -la /mnt/
# drwxr-xr-x  2 root root  0 Jan 15 10:00 shared   <- root:root, el appuser no puede escribir
```

**Solucion con mountOptions en la StorageClass:**

```yaml
# Uso: kubectl apply -f storageclass-azurefile-uid.yaml
#
# Configura Azure Files SMB con UID/GID especificos para que
# el usuario del contenedor tenga acceso correcto.
# Ajustar uid y gid al usuario que usa el contenedor.
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azurefile-uid-1000
provisioner: file.csi.azure.com
parameters:
  skuName: Standard_LRS
mountOptions:
- uid=1000                 # UID del usuario del contenedor
- gid=1000                 # GID del usuario del contenedor
- mfsymlinks
- cache=strict
- actimeo=30
- file_mode=0660           # Permisos de archivo: owner rw, group rw, other none
- dir_mode=0770            # Permisos de directorio
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: Immediate
```

**Alternativa — Usar NFS en lugar de SMB (mejor soporte de permisos):**

```yaml
# NFS respeta UID/GID de POSIX correctamente, a diferencia de SMB.
# Requiere Azure Files Premium con protocolo NFS habilitado.
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azurefile-nfs
provisioner: file.csi.azure.com
parameters:
  skuName: Premium_LRS
  protocol: nfs              # NFS 4.1 — permisos POSIX nativos
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: Immediate
```

```bash
# Con NFS, los permisos se configuran con securityContext en el Pod:
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000          # Kubernetes chown del volumen a este GID al montar
  containers:
  - name: app
    volumeMounts:
    - name: shared-data
      mountPath: /mnt/shared
```

---

### Tabla Resumen de Troubleshooting

| Problema | Causa Mas Comun | Comando de Diagnostico Rapido |
|----------|----------------|-------------------------------|
| PVC en Pending | StorageClass incorrecta | `kubectl describe pvc <name>` |
| PVC en Pending | CSI driver no funciona | `kubectl get pods -n kube-system | grep csi` |
| Multi-Attach error | RWO disco ya en otro nodo | `kubectl get volumeattachment` |
| ContainerCreating largo | Disco en AZ diferente | `kubectl describe pod <name>` |
| I/O lento | SKU incorrecto (Standard en vez de Premium) | `kubectl get pvc -o jsonpath='{.spec.storageClassName}'` |
| Disco lleno | Sin expansion o sin monitoreo | `kubectl exec -- df -h <mountPath>` |
| Permission denied en Azure Files | UID/GID mismatch en SMB | `kubectl exec -- id` + revisar StorageClass mountOptions |

---

## Resumen del Capitulo

El almacenamiento persistente es la fundacion de cualquier aplicacion con estado en Kubernetes. Sin el, toda base de datos, sistema de archivos compartido, o cola de mensajes es efimera — los datos desaparecen con el Pod.

**Los conceptos fundamentales que debes dominar:**

El problema que resolvemos es el filesystem efimero: cuando un Pod se reprograma en otro nodo (actualizacion, fallo, scaling), el almacenamiento local del contenedor desaparece. En cloud, esto es especialmente critico porque los nodos son fungibles por diseno.

**La eleccion entre Azure Disk y Azure Files determina el patron de acceso:**

- **Azure Disk** es block storage de alto rendimiento (IOPS hasta 160.000 con Ultra SSD) vinculado a un solo Pod a la vez (ReadWriteOnce). Es la opcion correcta para PostgreSQL, MySQL, MongoDB, Redis, y cualquier base de datos que requiere acceso exclusivo y alta velocidad de escritura aleatoria.

- **Azure Files** es un recurso compartido accesible desde multiples Pods en multiples nodos simultaneamente (ReadWriteMany). Usa SMB o NFS como protocolo. Es la opcion correcta para contenido compartido (WordPress multi-replica), logs centralizados, assets estaticos, y configuracion compartida.

**Las StorageClasses son el puente entre Kubernetes y Azure:**

AKS incluye StorageClasses preconfiguradas que cubren los casos principales: `managed-csi` (Standard SSD, default), `managed-csi-premium` (Premium SSD, produccion), `azurefile-csi` (SMB compartido), `azurefile-csi-premium` (NFS alto rendimiento). Para casos especiales, puedes crear StorageClasses personalizadas con ZRS, Ultra SSD, o politicas de retencion especificas.

El campo `volumeBindingMode: WaitForFirstConsumer` es critico para Azure Disk en clusters multi-zona: garantiza que el disco se crea en la misma zona de disponibilidad que el nodo donde se programa el Pod, evitando el error de "disk not in same zone as node".

**El aprovisionamiento dinamico elimina la gestion manual de discos:**

Cuando creas un PVC con un `storageClassName`, el CSI driver llama automaticamente a la Azure API para crear el disco o file share. No necesitas pre-provisionar recursos en Azure ni crear PersistentVolumes manualmente. El flujo es: PVC creado -> StorageClass -> CSI Driver -> Azure API -> disco creado -> PV creado -> PVC Bound.

**Los StatefulSets son obligatorios para bases de datos:**

A diferencia de los Deployments donde todos los Pods comparten el mismo PVC (lo que causaria corrupcion de datos en una DB), los StatefulSets usan `volumeClaimTemplates` para crear un PVC dedicado por cada replica. Cuando se elimina el StatefulSet, los PVCs NO se eliminan automaticamente — esta proteccion es intencional y evita perdidas de datos accidentales.

**Los VolumeSnapshots habilitan backup y recuperacion:**

Kubernetes tiene un sistema nativo de snapshots con tres recursos: `VolumeSnapshotClass` (configuracion del driver), `VolumeSnapshot` (la solicitud de captura), y `VolumeSnapshotContent` (el snapshot real en Azure). Los snapshots permiten crear nuevos PVCs con datos de un punto anterior, y se pueden automatizar con CronJobs. Para produccion, Azure Backup for AKS extiende esto a backup completo del cluster incluyendo recursos Kubernetes.

**El troubleshooting de almacenamiento sigue un patron sistematico:**

Siempre empezar con `kubectl describe pvc <name>` y `kubectl describe pod <name>` para leer los eventos. Los problemas mas comunes son: StorageClass inexistente (PVC Pending), disco ya attached en otro nodo (Multi-Attach error, RWO violation), disco en zona diferente al nodo (ContainerCreating largo), SKU insuficiente (I/O lento), y permisos UID/GID en Azure Files SMB.

**En el proximo capitulo** exploraremos Azure Key Vault integration con AKS — como gestionar secretos, certificados TLS, y claves de cifrado de forma segura usando el CSI Secrets Store driver, evitando almacenar informacion sensible como Kubernetes Secrets en etcd.

