# Lab Resumen: Almacenamiento Persistente en Kubernetes

Revision guiada de 60 minutos sobre PersistentVolumes, PersistentVolumeClaims,
StorageClasses y StatefulSets, disenada para ejecutarse en Minikube. Pensada para
personas que recien empiezan con Kubernetes y quieren entender desde cero como
los datos sobreviven a la eliminacion de un Pod.

**Duracion:** 60 minutos | **Nivel:** Principiante | **Archivo:** `almacenamiento-lab.yaml`

Un solo YAML despliega un namespace aislado con todos los recursos necesarios:
un PV y PVC enlazados, un Pod que escribe datos persistentes, un StatefulSet con
almacenamiento propio por replica, y un Pod verificador que lee los datos guardados.

---

## Conceptos Previos: Por que Necesitamos Almacenamiento Persistente

Antes de ejecutar cualquier comando, es importante entender el problema que este
laboratorio resuelve.

### El problema: los contenedores son como pizarras

Imagina que trabajas en una oficina y tienes una pizarra blanca donde anotas
tareas pendientes. Cada manana llegas, lees la pizarra y sabes que falta hacer.
Pero un dia la empresa cambia todas las pizarras por unas nuevas. Todo lo que
habia escrito en la pizarra antigua desaparece.

Los contenedores en Kubernetes funcionan exactamente igual. Cada contenedor tiene
su propio "sistema de archivos" interno — como la pizarra — donde puede leer y
escribir archivos. Pero cuando el contenedor se elimina y se crea uno nuevo
(por un fallo, por una actualizacion, por un cambio de nodo), ese sistema de
archivos interno desaparece con el. Es una pizarra que se borra sola.

**El problema concreto:** si despliegas una base de datos PostgreSQL en un
contenedor y un nodo del cluster falla, Kubernetes crea el Pod en otro nodo.
El contenedor nuevo tiene un sistema de archivos vacio. Todos los datos de
la base de datos — usuarios, pedidos, historial — han desaparecido.

### La solucion: un PersistentVolume es como un cuaderno

Ahora imagina que en lugar de anotar todo en la pizarra, lo anotas en un
cuaderno. Cuando cambian la pizarra, el cuaderno sigue estando contigo. Puedes
llevarlo a cualquier pizarra nueva y seguir trabajando desde donde lo dejaste.

Un **PersistentVolume (PV)** es ese cuaderno. Es un recurso de almacenamiento
que existe independientemente de los contenedores y los Pods. Cuando un Pod se
elimina y se recrea, puede "agarrar" el mismo cuaderno (el mismo PV) y encontrar
todos los datos intactos.

```
SIN almacenamiento persistente:

  Pod-A (escribe datos)  →  Pod eliminado  →  Pod-B nuevo  →  datos VACIOS
  [pizarra]                  [pizarra borrada]  [pizarra nueva]

CON almacenamiento persistente:

  Pod-A (escribe datos)  →  Pod eliminado  →  Pod-B nuevo  →  datos INTACTOS
  [pizarra] → [cuaderno]    [pizarra borrada]  [cuaderno existente]
```

---

### Tres componentes que trabajan juntos

El sistema de almacenamiento persistente en Kubernetes tiene tres piezas que
funcionan como un contrato entre el administrador del cluster y el desarrollador.

```
                    ADMINISTRADOR                    DESARROLLADOR
                    del cluster                      de la aplicacion
                         |                                 |
                         v                                 v
              ┌──────────────────────┐       ┌─────────────────────────┐
              │  PersistentVolume    │       │  PersistentVolumeClaim  │
              │  (PV)                │       │  (PVC)                  │
              │                      │       │                         │
              │  "Yo tengo 1GB de   │◄─────►│  "Necesito 500MB en    │
              │  almacenamiento en  │ Bound  │  modo lectura-escritura" │
              │  el nodo minikube"   │       │                         │
              └──────────────────────┘       └──────────┬──────────────┘
                                                        │ monta
                                                        v
                                             ┌──────────────────────┐
                                             │  Pod                 │
                                             │                      │
                                             │  volumes:            │
                                             │    - pvc: pvc-datos  │
                                             └──────────────────────┘
```

**PersistentVolume (PV):**
Es el disco real. Lo crea el administrador del cluster (o de forma automatica
la StorageClass). Describe un recurso de almacenamiento concreto: en Minikube
es un directorio del nodo (`hostPath`), en Azure es un Azure Disk o Azure Files,
en AWS es un EBS Volume. El PV existe a nivel del cluster, no de un namespace.

**PersistentVolumeClaim (PVC):**
Es la solicitud de almacenamiento. La crea el desarrollador. Indica cuanto espacio
necesita (`storage: 500Mi`) y en que modo (`ReadWriteOnce`). Kubernetes busca
automaticamente un PV compatible y los enlaza. El PVC existe en un namespace.

**StorageClass:**
Es el "catalogo" de tipos de almacenamiento disponibles. Define el provisioner
(quien crea los PVs), la politica de reciclado, y otros parametros. Con una
StorageClass configurada, los PVs se pueden crear automaticamente cuando un PVC
los solicita — sin intervencion manual del administrador.

---

### Modos de acceso: como puede montarse un volumen

Los modos de acceso definen cuantos nodos pueden montar el volumen y como.

```
MODO              ABREVIATURA   DESCRIPCION
─────────────────────────────────────────────────────────────────────
ReadWriteOnce     RWO           Solo 1 nodo puede montar en R/W
                                Como un disco duro USB: solo en 1 PC

ReadOnlyMany      ROX           N nodos pueden montar en solo lectura
                                Como un CD-ROM: todos pueden leer, nadie escribir

ReadWriteMany     RWX           N nodos pueden montar en R/W simultaneamente
                                Como una unidad de red compartida: todos leen y escriben

ReadWriteOncePod  RWOP          Solo 1 Pod (no solo 1 nodo) puede montar en R/W
                                (Kubernetes 1.22+) La restriccion mas estricta posible
```

Analogia para RWO vs RWX:
- **RWO** es como un libro fisico: solo una persona puede tenerlo en la mano y
  escribir en el al mismo tiempo.
- **RWX** es como un documento en Google Docs: multiples personas pueden editarlo
  simultaneamente desde computadoras distintas.

En Minikube (un solo nodo) la distincion entre RWO y RWX no es visible porque
todos los Pods corren en el mismo nodo. En un cluster real con multiples nodos,
intentar montar un volumen RWO desde dos nodos distintos genera un error.

---

### Reclaim Policies: que pasa con los datos cuando eliminas el PVC

```
POLITICA    QUE PASA CON EL PV          QUE PASA CON LOS DATOS
──────────────────────────────────────────────────────────────────────
Retain      Queda en estado "Released"  Se conservan en el disco
            El admin debe limpiarlo     El admin puede recuperarlos
            manualmente antes de
            reutilizarlo

Delete      Se elimina automaticamente  Se eliminan con el PV
            Tipico en cloud (Azure,     El disco subyacente se libera
            AWS, GCP)

Recycle     (obsoleto, no usar)         rm -rf en el directorio
            Se hace disponible
            nuevamente de forma
            automatica
```

Recomendacion practica:
- **Produccion con datos criticos:** `Retain` — nada se borra accidentalmente.
- **Entornos de desarrollo efimeros:** `Delete` — se limpia solo al terminar.
- **Minikube en este lab:** `Retain` para el PV manual, `Delete` para el StorageClass standard.

---

### Comparacion: emptyDir vs hostPath vs PVC

```
TIPO        DURACION              ALCANCE           CASO DE USO
────────────────────────────────────────────────────────────────────────────────
emptyDir    Mientras vive el Pod  Solo ese Pod      Compartir archivos entre
            (efimero)             (mismo namespace) contenedores del mismo Pod.
                                                    Cache temporal. Logs internos.

hostPath    Mientras exista el    Solo ese nodo     Labs y desarrollo local.
            directorio en el nodo (no portable)     Acceso a archivos del nodo
            (semi-persistente)                      (logs del sistema, Docker socket).
                                                    NUNCA en produccion real.

PVC/PV      Independiente del Pod Cluster completo  Bases de datos. Datos de
            (persistente)         (portable)        usuario. Cualquier dato que
                                                    debe sobrevivir a reinicios
                                                    y cambios de nodo.
```

Jerarquia de persistencia:
```
  [Mas efimero]                                          [Mas persistente]

  Sistema de       emptyDir        hostPath           PVC / PV
  archivos del  ─────────────────────────────────────────────────►
  contenedor
  (desaparece      (desaparece     (sobrevive al      (sobrevive a Pods,
  al reinicio)     con el Pod)     Pod pero no        reinicios, cambios
                                   al cambio          de nodo y escalado)
                                   de nodo)
```

---

## Conceptos Cubiertos

| Componente | Concepto demostrado |
|------------|---------------------|
| `pv-datos` | PersistentVolume hostPath que representa el disco real en Minikube |
| `pvc-datos` | PersistentVolumeClaim que solicita 500Mi del PV y queda en estado Bound |
| `storage-local` | StorageClass con provisioner manual y politica Retain |
| `pod-escritor` | Pod que monta el PVC y escribe datos que sobreviven a su eliminacion |
| `pod-verificador` | Pod que lee los mismos datos del PVC montado en modo readOnly |
| `statefulset-db` | StatefulSet con volumeClaimTemplate: 1 PVC automatico por replica |
| `db-headless` | Service headless requerido por el StatefulSet para DNS individual |
| `storage-info` | ConfigMap montado como volumen de archivos de texto |

---

## Archivos del Lab

| Archivo | Descripcion |
|---------|-------------|
| `almacenamiento-lab.yaml` | YAML unico con todos los recursos: Namespace + ConfigMap + StorageClass + PV + PVC + Pod escritor + Pod verificador + StatefulSet + Service headless |
| `cleanup.sh` | Elimina el namespace, PVs del cluster y StorageClass. Restaura contexto. |

---

## Paso 0: Preparar Minikube (5 min)

Este paso es obligatorio. Los PersistentVolumes de tipo `hostPath` necesitan
que el directorio exista en el nodo Minikube antes de que el Pod lo use.

```bash
# Verificar que Minikube esta corriendo
minikube status
```

**Salida esperada:**

```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

Si no esta corriendo, iniciarlo:

```bash
minikube start
```

Crear el directorio en el nodo Minikube que usara el PersistentVolume:

```bash
minikube ssh "sudo mkdir -p /data/pv-datos && sudo chmod 777 /data/pv-datos"
```

**Que hace este comando?**
`minikube ssh` abre una conexion SSH al nodo virtual de Minikube (la VM que actua
como el "servidor" del cluster). Dentro de ese nodo crea el directorio `/data/pv-datos`
con permisos abiertos para que los contenedores puedan escribir en el sin restricciones
de permisos. Sin este directorio, el Pod escritor quedaria en estado Pending o
mostraria errores de montaje.

Verificar que el directorio existe en el nodo:

```bash
minikube ssh "ls -la /data/"
```

**Salida esperada:**

```
total 12
drwxr-xr-x 3 root root 4096 Mar  3 10:00 .
drwxr-xr-x 21 root root 4096 Mar  3 09:55 ..
drwxrwxrwx 2 root root 4096 Mar  3 10:00 pv-datos
```

---

## Paso 1: Desplegar Todo (2 min)

```bash
kubectl apply -f almacenamiento-lab.yaml
```

**Salida esperada:**

```
namespace/lab-almacenamiento created
configmap/storage-info created
storageclass/storage-local created
persistentvolume/pv-datos created
persistentvolumeclaim/pvc-datos created
pod/pod-escritor created
pod/pod-verificador created
statefulset.apps/statefulset-db created
service/db-headless created
```

Esperar a que los recursos esten listos (el init container de pod-verificador
necesita que pod-escritor escriba primero, puede tardar 15-30 segundos):

```bash
kubectl get all -n lab-almacenamiento
```

**Salida esperada (despues de ~30s):**

```
NAME                  READY   STATUS    RESTARTS   AGE
pod/pod-escritor      1/1     Running   0          30s
pod/pod-verificador   1/1     Running   0          25s
pod/statefulset-db-0  1/1     Running   0          30s
pod/statefulset-db-1  1/1     Running   0          28s

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
service/db-headless  ClusterIP   None         <none>        5432/TCP   30s

NAME                             READY   AGE
statefulset.apps/statefulset-db  2/2     30s
```

**Por que hay un init container en pod-verificador?**
El Pod verificador tiene un init container llamado `esperar-datos` que revisa
cada 5 segundos si el archivo `registro.txt` ya existe en el PVC. Solo cuando
ese archivo existe (escrito por pod-escritor), el init container termina con
exit 0 y el contenedor principal arranca. Esto garantiza que el verificador
siempre encuentre datos disponibles.

---

## Paso 2: Verificar PV y PVC en estado Bound (5 min)

El estado `Bound` significa que el PVC y el PV se han enlazado correctamente.
Es el estado esperado en un sistema de almacenamiento funcional.

Verificar el PersistentVolume:

```bash
kubectl get pv pv-datos
```

**Salida esperada:**

```
NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                               STORAGECLASS    AGE
pv-datos   1Gi        RWO            Retain           Bound    lab-almacenamiento/pvc-datos         storage-local   1m
```

Columnas importantes:
- **STATUS: Bound** significa que el PV esta enlazado a un PVC y en uso.
- **CLAIM: lab-almacenamiento/pvc-datos** indica que PVC lo esta usando.
- **RECLAIM POLICY: Retain** confirma que los datos se conservan al eliminar el PVC.

Verificar el PersistentVolumeClaim:

```bash
kubectl get pvc -n lab-almacenamiento
```

**Salida esperada:**

```
NAME        STATUS   VOLUME     CAPACITY   ACCESS MODES   STORAGECLASS    AGE
pvc-datos   Bound    pv-datos   1Gi        RWO            storage-local   1m
```

Ver los detalles completos del PVC:

```bash
kubectl describe pvc pvc-datos -n lab-almacenamiento
```

**Salida esperada (fragmento relevante):**

```
Name:          pvc-datos
Namespace:     lab-almacenamiento
StorageClass:  storage-local
Status:        Bound
Volume:        pv-datos
Capacity:      1Gi
Access Modes:  RWO
VolumeMode:    Filesystem
```

**Que significa si el estado es `Pending` en lugar de `Bound`?**
El PVC no encontro un PV compatible. Las causas mas comunes son:
1. El `storageClassName` del PVC no coincide con el del PV.
2. La capacidad solicitada en el PVC es mayor que la disponible en el PV.
3. El `accessMode` del PVC no es compatible con los modos del PV.
4. La StorageClass usa `WaitForFirstConsumer` y no hay Pod que la solicite todavia.

---

## Paso 3: Escribir Datos Persistentes (5 min)

El Pod escritor ya ha escrito datos al iniciar. Vamos a verificar lo que escribio
y a anadir datos adicionales manualmente para demostrar la persistencia.

Ver los datos que pod-escritor escribio automaticamente al arrancar:

```bash
kubectl exec pod-escritor -n lab-almacenamiento -- cat /datos/registro.txt
```

**Salida esperada:**

```
=== Pod Escritor iniciado ===
Timestamp: Mon Mar  3 10:05:23 UTC 2026
Pod hostname: pod-escritor
Pod IP: 10.244.0.5

MENSAJE IMPORTANTE: Este archivo fue escrito por pod-escritor.
Si eliminas este Pod y creas uno nuevo, este archivo sigue aqui.
Eso demuestra que los datos persisten en el PV, no en el Pod.
```

Anadir datos adicionales manualmente desde fuera del Pod:

```bash
kubectl exec pod-escritor -n lab-almacenamiento -- \
  sh -c 'echo "Linea agregada manualmente: $(date)" >> /datos/registro.txt'
```

Verificar que el dato adicional se guardo:

```bash
kubectl exec pod-escritor -n lab-almacenamiento -- cat /datos/registro.txt
```

Ver todos los archivos en el volumen:

```bash
kubectl exec pod-escritor -n lab-almacenamiento -- ls -la /datos/
```

**Salida esperada:**

```
total 16
drwxr-xr-x 2 root root 4096 Mar  3 10:05 .
drwxr-xr-x 1 root root 4096 Mar  3 10:05 ..
-rw-r--r-- 1 root root  512 Mar  3 10:05 actividad.log
-rw-r--r-- 1 root root  380 Mar  3 10:05 registro.txt
```

Verificar que pod-verificador puede leer los mismos datos:

```bash
kubectl logs pod-verificador -n lab-almacenamiento
```

**Salida esperada (fragmento):**

```
=== Pod Verificador: leyendo datos del PVC ===

--- Contenido de /datos/registro.txt ---
=== Pod Escritor iniciado ===
Timestamp: Mon Mar  3 10:05:23 UTC 2026
...

--- Archivos en /datos/ ---
total 16
-rw-r--r-- 1 root root 512 Mar  3 10:05 actividad.log
-rw-r--r-- 1 root root 380 Mar  3 10:05 registro.txt
```

---

## Paso 4: Eliminar el Pod y Demostrar Persistencia (10 min)

Este es el paso central del laboratorio. Vamos a demostrar que los datos
sobreviven a la eliminacion y recreacion del Pod.

Anotar el timestamp del archivo para confirmar que son los mismos datos despues:

```bash
kubectl exec pod-escritor -n lab-almacenamiento -- \
  sh -c 'echo "ANTES DEL REINICIO: $(date)" >> /datos/registro.txt && cat /datos/registro.txt'
```

Eliminar el Pod escritor:

```bash
kubectl delete pod pod-escritor -n lab-almacenamiento
```

**Salida esperada:**

```
pod "pod-escritor" deleted
```

Verificar que el Pod fue eliminado:

```bash
kubectl get pods -n lab-almacenamiento
```

**Salida esperada:**

```
NAME                  READY   STATUS    RESTARTS   AGE
pod/pod-verificador   1/1     Running   0          8m
pod/statefulset-db-0  1/1     Running   0          8m
pod/statefulset-db-1  1/1     Running   0          8m
```

En este momento, `pod-escritor` no existe. Pero los datos en el PVC siguen
estando ahi. Podemos verificarlo leyendo desde pod-verificador:

```bash
kubectl exec pod-verificador -n lab-almacenamiento -- ls -la /datos/
kubectl exec pod-verificador -n lab-almacenamiento -- cat /datos/registro.txt
```

**Salida esperada:** Los mismos archivos con el mismo contenido. El texto
"ANTES DEL REINICIO" que anadimos antes de eliminar el Pod aparece intacto.

Ahora recrear el Pod escritor aplicando el YAML nuevamente:

```bash
kubectl apply -f almacenamiento-lab.yaml
```

Esperar a que el nuevo Pod este Running:

```bash
kubectl get pod pod-escritor -n lab-almacenamiento --watch
```

Una vez que este Running, verificar que el nuevo Pod encuentra los datos
del Pod anterior:

```bash
kubectl exec pod-escritor -n lab-almacenamiento -- cat /datos/registro.txt
```

**Salida esperada:** El archivo contiene TODOS los datos anteriores (incluyendo
"ANTES DEL REINICIO") MAS las nuevas lineas escritas por el Pod nuevo al arrancar.

```
=== Pod Escritor iniciado ===
Timestamp: Mon Mar  3 10:05:23 UTC 2026       <- escritura del Pod original
Pod hostname: pod-escritor
...
ANTES DEL REINICIO: Mon Mar  3 10:15:00 UTC 2026  <- anadido manualmente
=== Pod Escritor iniciado ===
Timestamp: Mon Mar  3 10:18:45 UTC 2026       <- escritura del Pod nuevo
Pod hostname: pod-escritor
...
```

**Que acabamos de demostrar?**
El Pod nuevo NO tiene ninguna conexion con el Pod anterior. Son instancias
distintas del mismo contenedor. Pero ambos acceden al mismo PVC, que a su vez
apunta al mismo PV (el directorio `/data/pv-datos` en el nodo Minikube). Los
datos viven en el disco, no en el contenedor. El contenedor puede morir y
revivir tantas veces como quiera — el cuaderno siempre lo espera con las notas.

---

## Paso 5: Explorar la StorageClass (5 min)

Las StorageClasses son el mecanismo que permite el aprovisionamiento automatico
de PersistentVolumes sin intervencion manual del administrador.

Ver la StorageClass creada por el lab:

```bash
kubectl get storageclass storage-local
kubectl describe storageclass storage-local
```

**Salida esperada:**

```
Name:            storage-local
IsDefaultClass:  No
Annotations:     <none>
Provisioner:     kubernetes.io/no-provisioner
Parameters:      <none>
AllowVolumeExpansion:  False
MountOptions:    <none>
ReclaimPolicy:   Retain
VolumeBindingMode:  WaitForFirstConsumer
Events:          <none>
```

Ver todas las StorageClasses disponibles en el cluster (incluyendo las de Minikube):

```bash
kubectl get storageclass
```

**Salida esperada:**

```
NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE      AGE
standard (default)   k8s.io/minikube-hostpath   Delete          Immediate              2h
storage-local        kubernetes.io/no-provisioner  Retain       WaitForFirstConsumer   10m
```

**Diferencias clave entre `standard` y `storage-local`:**

```
CARACTERISTICA          standard                    storage-local
────────────────────────────────────────────────────────────────────
Provisioner             k8s.io/minikube-hostpath    kubernetes.io/no-provisioner
Aprovisionamiento       Automatico (PVs se crean    Manual (el admin crea los PVs)
                        solos al crear PVCs)
ReclaimPolicy           Delete (PV se borra al      Retain (PV y datos se conservan
                        eliminar el PVC)            al eliminar el PVC)
VolumeBindingMode       Immediate (PV se            WaitForFirstConsumer (espera
                        enlaza de inmediato)        a que un Pod lo solicite)
Caso de uso             Labs rapidos, Minikube,     Produccion on-premises, datos
                        entornos efimeros           criticos que no deben borrarse
```

Verificar como el StatefulSet usa la StorageClass `standard` (no `storage-local`):

```bash
kubectl get pvc -n lab-almacenamiento
```

**Salida esperada:**

```
NAME                          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS    AGE
pvc-datos                     Bound    pv-datos                                   1Gi        RWO            storage-local   10m
datos-db-statefulset-db-0     Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   256Mi      RWO            standard        10m
datos-db-statefulset-db-1     Bound    pvc-yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy   256Mi      RWO            standard        10m
```

Los PVCs del StatefulSet (`datos-db-statefulset-db-0` y `datos-db-statefulset-db-1`)
fueron creados automaticamente por Minikube usando la StorageClass `standard`,
sin que tuvieramos que crear PVs manualmente para ellos.

---

## Paso 6: StatefulSet con Almacenamiento Independiente (10 min)

Un StatefulSet garantiza que cada replica tiene identidad estable y
almacenamiento propio. Este paso demuestra por que los StatefulSets son
esenciales para bases de datos.

Ver el estado del StatefulSet:

```bash
kubectl get statefulset statefulset-db -n lab-almacenamiento
```

**Salida esperada:**

```
NAME             READY   AGE
statefulset-db   2/2     10m
```

Observar los nombres predecibles de los Pods (db-0, db-1, no hashes aleatorios):

```bash
kubectl get pods -n lab-almacenamiento -l rol=base-de-datos
```

**Salida esperada:**

```
NAME                 READY   STATUS    RESTARTS   AGE
statefulset-db-0     1/1     Running   0          10m
statefulset-db-1     1/1     Running   0          10m
```

**Por que los nombres son db-0 y db-1 y no hashes aleatorios?**
En un Deployment normal, los Pods reciben nombres como `my-deploy-7d4f9b-xk2p1`.
El sufijo es aleatorio porque los Pods son intercambiables. En un StatefulSet,
los Pods tienen nombres como `statefulset-db-0`, `statefulset-db-1`. Son
predecibles y estables porque cada uno tiene una identidad distinta: db-0 es
siempre el nodo maestro, db-1 es siempre la primera replica.

Verificar que cada Pod tiene su propio PVC:

```bash
kubectl describe pod statefulset-db-0 -n lab-almacenamiento | grep "ClaimName"
kubectl describe pod statefulset-db-1 -n lab-almacenamiento | grep "ClaimName"
```

**Salida esperada:**

```
ClaimName:  datos-db-statefulset-db-0
ClaimName:  datos-db-statefulset-db-1
```

Escribir datos distintos en cada replica para demostrar el aislamiento:

```bash
# Escribir en db-0
kubectl exec statefulset-db-0 -n lab-almacenamiento -- \
  sh -c 'echo "Datos exclusivos de db-0: $(date)" > /var/data/mi-dato.txt'

# Escribir en db-1
kubectl exec statefulset-db-1 -n lab-almacenamiento -- \
  sh -c 'echo "Datos exclusivos de db-1: $(date)" > /var/data/mi-dato.txt'
```

Verificar que los datos de cada Pod son independientes:

```bash
echo "=== db-0 ===" && kubectl exec statefulset-db-0 -n lab-almacenamiento -- cat /var/data/mi-dato.txt
echo "=== db-1 ===" && kubectl exec statefulset-db-1 -n lab-almacenamiento -- cat /var/data/mi-dato.txt
```

**Salida esperada:**

```
=== db-0 ===
Datos exclusivos de db-0: Mon Mar  3 10:25:00 UTC 2026
=== db-1 ===
Datos exclusivos de db-1: Mon Mar  3 10:25:01 UTC 2026
```

Los datos de db-0 y db-1 son completamente independientes. Cada Pod tiene
su propio "cuaderno" — su propio PVC montado en su propio PV.

Verificar el acceso DNS individual que provee el Service headless:

```bash
# Ejecutar desde pod-verificador para resolver el DNS de cada replica
kubectl exec pod-verificador -n lab-almacenamiento -- \
  nslookup statefulset-db-0.db-headless.lab-almacenamiento.svc.cluster.local 2>/dev/null || \
kubectl exec pod-verificador -n lab-almacenamiento -- \
  wget -qO- statefulset-db-0.db-headless.lab-almacenamiento.svc.cluster.local 2>&1 | head -3
```

El formato del DNS individual es:
`<pod-name>.<service-name>.<namespace>.svc.cluster.local`
Ej: `statefulset-db-0.db-headless.lab-almacenamiento.svc.cluster.local`

Esto permite que db-0 y db-1 se encuentren entre si por nombre, no por IP
efimera — exactamente lo que necesita un sistema de replicacion de base de datos.

---

## Paso 7: Verificar Reclaim Policy (5 min)

La Reclaim Policy define que pasa con los datos cuando se elimina el PVC.
Vamos a demostrar que con `Retain`, el PV y sus datos sobreviven al PVC.

Ver el estado actual del PV (debe ser `Bound`):

```bash
kubectl get pv pv-datos
```

**Salida esperada:**

```
NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                               STORAGECLASS
pv-datos   1Gi        RWO            Retain           Bound    lab-almacenamiento/pvc-datos         storage-local
```

Ahora eliminar SOLO el PVC (no el namespace, no el PV):

```bash
kubectl delete pvc pvc-datos -n lab-almacenamiento
```

**Salida esperada:**

```
persistentvolumeclaim "pvc-datos" deleted
```

Ver el estado del PV despues de eliminar el PVC:

```bash
kubectl get pv pv-datos
```

**Salida esperada:**

```
NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                               STORAGECLASS
pv-datos   1Gi        RWO            Retain           Released   lab-almacenamiento/pvc-datos         storage-local
```

**El estado cambio de `Bound` a `Released`.**

Esto significa:
- El PVC fue eliminado.
- El PV sigue existiendo (no fue borrado).
- Los datos en el directorio `/data/pv-datos` del nodo Minikube siguen intactos.
- El PV esta disponible pero NO puede ser reclamado por un nuevo PVC todavia
  porque contiene datos de un PVC anterior (el campo `claimRef` aun esta lleno).

Verificar los datos directamente en el nodo Minikube:

```bash
minikube ssh "ls -la /data/pv-datos/ && cat /data/pv-datos/registro.txt"
```

**Salida esperada:** Los archivos siguen ahi, incluyendo todos los datos
escritos a lo largo del laboratorio.

**Que tendria que hacer un administrador para reutilizar este PV?**

```bash
# 1. Verificar y recuperar los datos si es necesario
#    (copiarlos a otro lugar antes de limpiar)

# 2. Limpiar los datos del PV manualmente
minikube ssh "rm -rf /data/pv-datos/*"

# 3. Eliminar el campo claimRef del PV para que quede en estado Available
kubectl patch pv pv-datos --type=json \
  -p='[{"op": "remove", "path": "/spec/claimRef"}]'

# 4. Verificar que el PV ahora esta en Available
kubectl get pv pv-datos
# STATUS deberia ser: Available
```

Restaurar el PVC para continuar con el resto del lab (cleanup.sh necesita
que el namespace y recursos existan para limpiarlos correctamente):

```bash
kubectl apply -f almacenamiento-lab.yaml
```

---

## Paso 8: Limpieza (2 min)

```bash
chmod +x cleanup.sh
./cleanup.sh
```

**Salida esperada:**

```
Limpieza del Lab Resumen: Almacenamiento Persistente...

[1/4] Eliminando namespace lab-almacenamiento...
  namespace/lab-almacenamiento eliminado
  Incluye: pod-escritor, pod-verificador, statefulset-db
  Incluye: pvc-datos, datos-db-statefulset-db-0, datos-db-statefulset-db-1
  Incluye: db-headless (Service), storage-info (ConfigMap)

[2/4] Eliminando PersistentVolumes del cluster...
  persistentvolume/pv-datos eliminado

[3/4] Eliminando StorageClass storage-local...
  storageclass/storage-local eliminada

[4/4] Restaurando contexto...
  Contexto restaurado a namespace 'default'

Limpieza completada!

Nota: Los datos del hostPath en el nodo Minikube persisten.
Para eliminarlos completamente:
  minikube ssh "rm -rf /data/pv-datos"
```

O manualmente en dos pasos:

```bash
# Paso A: eliminar el namespace (incluye PVCs y recursos con namespace)
kubectl delete namespace lab-almacenamiento

# Paso B: eliminar los PVs (recursos del cluster, no del namespace)
kubectl delete pv pv-datos
kubectl delete storageclass storage-local

# Restaurar contexto
kubectl config set-context --current --namespace=default
```

---

## Checklist de Conocimientos

Marca cada concepto que puedas explicar con tus propias palabras:

- [ ] Un PV (PersistentVolume) es el almacenamiento real, creado por el administrador
- [ ] Un PVC (PersistentVolumeClaim) es la solicitud de almacenamiento, creada por el desarrollador
- [ ] El estado `Bound` significa que un PVC y un PV se han enlazado correctamente
- [ ] `hostPath` almacena datos en un directorio del nodo — solo para labs, nunca en produccion
- [ ] `ReadWriteOnce` (RWO) significa que solo un nodo puede montar el volumen en R/W
- [ ] `ReadWriteMany` (RWX) permite que multiples nodos monten el volumen simultaneamente
- [ ] `ReclaimPolicy: Retain` conserva el PV y sus datos cuando el PVC se elimina
- [ ] `ReclaimPolicy: Delete` elimina el PV automaticamente cuando el PVC se elimina
- [ ] Una StorageClass con `kubernetes.io/no-provisioner` requiere PVs creados manualmente
- [ ] Un StatefulSet crea un PVC propio por replica usando `volumeClaimTemplate`
- [ ] Los Pods de un StatefulSet tienen nombres predecibles: `nombre-0`, `nombre-1`
- [ ] Un Service headless (`clusterIP: None`) da DNS individual a cada Pod del StatefulSet
- [ ] Los datos en un PV sobreviven a la eliminacion y recreacion del Pod que lo usaba

---

## Errores Comunes para Principiantes

**"El PVC esta en Pending, no en Bound"**

```bash
# Diagnostico: ver por que no se enlaza
kubectl describe pvc pvc-datos -n lab-almacenamiento | grep -A 5 "Events:"
```

Causas frecuentes:
1. `storageClassName` del PVC no coincide con el del PV.
2. La capacidad solicitada es mayor que la disponible en el PV.
3. El directorio hostPath no existe en el nodo (`minikube ssh "ls /data/"`).
4. StorageClass con `WaitForFirstConsumer`: el PVC no se enlaza hasta que un Pod lo solicite.

**"El Pod esta en Pending con error de montaje"**

```bash
kubectl describe pod pod-escritor -n lab-almacenamiento | grep -A 10 "Events:"
```

Mensaje tipico: `Unable to attach or mount volumes: ... hostPath ... no such file or directory`
Solucion: ejecutar el Paso 0 para crear el directorio en el nodo Minikube.

**"Los datos del PV desaparecieron al eliminar el namespace"**

Los PVs son recursos del cluster (no del namespace). Al eliminar el namespace se
eliminan los PVCs, pero los PVs permanecen. Sin embargo, si la ReclaimPolicy es
`Delete`, el PV y sus datos se borran cuando el PVC se elimina.
Solucion: usar `ReclaimPolicy: Retain` para datos criticos.

**"El StatefulSet queda en 0/2 Ready"**

```bash
kubectl describe statefulset statefulset-db -n lab-almacenamiento
kubectl get events -n lab-almacenamiento --sort-by='.lastTimestamp' | tail -10
```

Causa frecuente: Minikube no tiene suficientes recursos (CPU/RAM) para las
replicas. Verificar con `minikube status` y reiniciar si es necesario.

---

## Resumen Visual

```
                    CLUSTER KUBERNETES (Minikube)
                    ────────────────────────────────────────────────
                    NAMESPACE: lab-almacenamiento

  Pod-escritor ────────────────────────────────────────────┐
  [pod-escritor]                                           │
    container: escritor                                    │
    volumeMount: /datos ──────────────────────────►  PVC: pvc-datos
                                                     (500Mi, RWO)
  Pod-verificador                                          │
  [pod-verificador]                                        │
    container: verificador                                 │
    volumeMount: /datos (readOnly) ───────────────────────►┘
                                                           │ enlazado
                                                           ▼
                                                    PV: pv-datos
                                                    (1Gi, Retain)
                                                    StorageClass: storage-local
                                                           │ hostPath
                                                           ▼
                                                    /data/pv-datos
                                                    (directorio en nodo Minikube)


  StatefulSet: statefulset-db
  ───────────────────────────
  Pod: statefulset-db-0 ──► PVC: datos-db-statefulset-db-0 (256Mi, standard)
  Pod: statefulset-db-1 ──► PVC: datos-db-statefulset-db-1 (256Mi, standard)

  Cada Pod tiene su propio PVC. Los datos de db-0 y db-1 son independientes.
  Service headless db-headless provee DNS individual:
    statefulset-db-0.db-headless.lab-almacenamiento.svc.cluster.local
    statefulset-db-1.db-headless.lab-almacenamiento.svc.cluster.local
```

---

## Relevancia CKAD / CKA

Este laboratorio cubre los siguientes temas de examen:

| Tema | Examen | Frecuencia |
|------|--------|------------|
| Crear PersistentVolume y PersistentVolumeClaim | CKA | Alta |
| Montar PVC en un Pod | CKAD | Alta |
| Configurar StorageClass | CKA | Media |
| StatefulSet con volumeClaimTemplate | CKAD / CKA | Alta |
| Diagnosticar PVC en Pending | CKA | Alta |
| Reclaim Policies (Retain, Delete) | CKA | Media |
| hostPath vs PVC | CKAD | Media |

**Comandos clave para el examen:**

```bash
# Ver todos los PVs del cluster
kubectl get pv

# Ver PVCs en un namespace
kubectl get pvc -n <namespace>

# Diagnosticar un PVC en Pending
kubectl describe pvc <nombre-pvc> -n <namespace>

# Ver que StorageClasses existen
kubectl get storageclass

# Ver los PVCs de un StatefulSet
kubectl get pvc -n <namespace> -l app=<nombre-app>

# Ejecutar dentro de un Pod para verificar el volumen montado
kubectl exec <pod> -n <namespace> -- ls -la <mountPath>
kubectl exec <pod> -n <namespace> -- df -h <mountPath>
```

---

## Proximos Pasos

Despues de completar este lab, el siguiente nivel es trabajar con almacenamiento
en Azure AKS:

- **Azure Disk** (ReadWriteOnce): equivalente a `hostPath` pero en la nube,
  con discos gestionados por Azure que siguen al Pod aunque cambie de nodo.
- **Azure Files** (ReadWriteMany): almacenamiento compartido SMB/NFS para
  multiples Pods en multiples nodos simultaneamente.
- **Snapshots de volumenes**: copias de seguridad instantaneas de PVs usando
  `VolumeSnapshot` en Kubernetes.
- **Expansion de volumenes**: aumentar la capacidad de un PVC sin tiempo de
  inactividad con `allowVolumeExpansion: true` en la StorageClass.
