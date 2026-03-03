# Resumen Rapido: Cluster Maintenance & Upgrades

**Duracion:** 15 minutos | **Nivel:** Repaso | **Archivo:** `maintenance-lab.yaml`

Resumen practico de las 4 areas clave de mantenimiento de clusters Kubernetes cubiertas en el Modulo 23: etcd backup/restore, cluster upgrades, node drain/cordon, y gestion de certificados.

---

## Conceptos Previos

Antes de empezar, es importante entender que Kubernetes es un sistema vivo: nodos fallan, versiones quedan obsoletas, certificados vencen, y la base de datos interna necesita respaldo. El mantenimiento de un cluster no es algo que se hace una vez; es una actividad continua y planificada.

Piensa en un cluster Kubernetes como un edificio moderno con varios pisos:

- **etcd** es el archivo central del edificio — guarda los planos de todo lo que existe
- **Los nodos** son los pisos donde viven los inquilinos (Pods)
- **Los certificados** son los carnets de identidad que usan los componentes para hablar entre si
- **Las actualizaciones** son como renovar la estructura del edificio mientras los inquilinos siguen viviendo ahi

Este laboratorio te guia a traves de las operaciones mas importantes de mantenimiento, explicando cada concepto desde cero.

---

## Mapa Conceptual

Las 4 areas de mantenimiento que cubre este modulo se relacionan en un ciclo operacional:

```
        [etcd backup/restore]
               |
    Protege datos del cluster
               |
    [Cluster Upgrade]  ----  Requiere coordinacion de nodos
               |
       drain -> upgrade -> uncordon
               |
    [Node Drain/Cordon]
               |
    Evacuacion controlada con PDB
               |
    [Certificate Management]
               |
    Renovacion sin interrupcion
```

---

## Area 1: etcd Backup/Restore

### Que es etcd y por que hacerle backup

**etcd** es la base de datos de Kubernetes. Almacena absolutamente todo el estado del cluster: que Pods existen, que Deployments hay, que Secrets y ConfigMaps se han creado, que nodos forman el cluster, y mucho mas.

Si etcd se pierde o corrompe, el cluster entero queda inutilizable porque nadie sabe que estaba corriendo antes. Es como perder todos los planos de un edificio: sigues teniendo el edificio fisico, pero no sabes que hay en cada cuarto ni como reconectarlo.

Hacer un backup de etcd antes de cualquier operacion de mantenimiento es equivalente a guardar una copia de seguridad de todos tus archivos importantes antes de actualizar tu sistema operativo. Si algo sale mal, puedes volver al estado anterior.

**Terminos nuevos:**
- **etcd**: base de datos clave-valor distribuida que Kubernetes usa como su "cerebro"
- **snapshot**: foto instantanea del estado completo de etcd en un momento dado
- **ETCDCTL_API=3**: version del protocolo de comunicacion con etcd (la version 3 es la actual)
- **TLS**: protocolo de seguridad que cifra la comunicacion; etcd lo requiere para autenticarse

### Comandos esenciales

```bash
# Backup de etcd
# Este comando conecta a etcd y guarda una copia de todo su contenido en un archivo .db
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

Salida esperada:

```
{"level":"info","ts":"...","caller":"snapshot/v3_snapshot.go:65","msg":"created temporary db file","path":"/backup/etcd-snapshot.db.part"}
{"level":"info","ts":"...","caller":"snapshot/v3_snapshot.go:68","msg":"fetching snapshot"}
{"level":"info","ts":"...","caller":"snapshot/v3_snapshot.go:79","msg":"fetched snapshot","endpoint":"https://127.0.0.1:2379"}
Snapshot saved at /backup/etcd-snapshot.db
```

El mensaje `Snapshot saved at` confirma que el archivo de backup se creo correctamente.

```bash
# Verificar backup: confirma que el archivo es valido y no esta corrupto
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-snapshot.db --write-out=table
```

Salida esperada:

```
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| fc9bf99e |   100234 |       1234 |     4.2 MB |
+----------+----------+------------+------------+
```

La tabla muestra el hash de verificacion (para detectar corrupcion), el numero de revision (contador de cambios), el total de claves guardadas, y el tamano del archivo. Si el comando devuelve una tabla con datos, el backup es valido.

```bash
# Restore (ejecutar en nodo control plane, detener API server primero)
# Este comando reconstruye etcd a partir del archivo de backup
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-restored
```

**Nota importante:** Antes de hacer un restore, el API server de Kubernetes debe estar detenido. Luego se actualiza la configuracion de etcd para que apunte al nuevo directorio de datos (`/var/lib/etcd-restored`), y se reinicia.

---

## Area 2: Cluster Upgrade

### Que significa actualizar Kubernetes y por que es delicado

Actualizar Kubernetes es como actualizar el sistema operativo de un servidor de produccion que tiene clientes activos. No puedes simplemente apagarlo y encenderlo — necesitas hacerlo de forma ordenada para que las aplicaciones sigan funcionando durante el proceso.

En un cluster con varios nodos, la estrategia es:
1. Actualizar primero el **control plane** (el "cerebro" del cluster)
2. Luego actualizar cada **nodo worker** uno por uno, moviendo sus cargas a otros nodos antes de actualizar

**Terminos nuevos:**
- **kubeadm**: herramienta oficial para instalar y actualizar clusters Kubernetes
- **version menor**: en `v1.28.0` -> `v1.29.0`, el numero del medio es la version menor
- **control plane**: los componentes centrales de Kubernetes (API server, etcd, scheduler, controller manager)
- **kubelet**: agente que corre en cada nodo y ejecuta las instrucciones del control plane

### Proceso estandar con kubeadm (v1.28 -> v1.29)

```bash
# En el nodo control plane:

# Paso 1: Instalar la nueva version de kubeadm
apt-get install -y kubeadm=1.29.0-1.1

# Paso 2: Verificar que el upgrade es posible y ver los cambios
kubeadm upgrade plan
```

Salida esperada (fragmento):

```
COMPONENT                 CURRENT   TARGET
kube-apiserver            v1.28.0   v1.29.0
kube-controller-manager   v1.28.0   v1.29.0
kube-scheduler            v1.28.0   v1.29.0
kube-proxy                v1.28.0   v1.29.0
CoreDNS                   v1.10.1   v1.11.1
etcd                      3.5.9     3.5.10

You can now apply the upgrade by executing the following command:
  kubeadm upgrade apply v1.29.0
```

El `upgrade plan` es solo de lectura — no cambia nada. Es como mirar el presupuesto antes de aprobar una obra.

```bash
# Paso 3: Aplicar el upgrade en el control plane
kubeadm upgrade apply v1.29.0

# Paso 4: Actualizar kubelet y kubectl en el nodo control plane
apt-get install -y kubelet=1.29.0-1.1 kubectl=1.29.0-1.1
systemctl restart kubelet

# En cada nodo worker (repetir el proceso por cada uno):
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
# [en el nodo worker]: apt-get install -y kubeadm=1.29.0-1.1 kubelet=1.29.0-1.1
# [en el nodo worker]: kubeadm upgrade node && systemctl restart kubelet
kubectl uncordon <node>
```

La secuencia `drain -> upgrade -> uncordon` garantiza que los Pods se muevan a otros nodos antes de que el nodo sea actualizado, y luego vuelvan cuando el nodo este listo.

---

## Area 3: Node Drain/Cordon

### Que significan cordon, drain y uncordon

Imagina que un nodo es un piso de un edificio donde viven varios inquilinos (Pods). Necesitas hacer remodelaciones en ese piso:

- **Cordon** es colgar un letrero de "no se aceptan nuevos inquilinos" — los que ya viven ahi se quedan, pero no entran mas
- **Drain** es evacuar el piso — se avisa a todos los inquilinos que deben mudarse a otro piso, y se cierra el acceso a nuevos inquilinos
- **Uncordon** es quitar el letrero — el piso esta listo y vuelve a aceptar inquilinos

Los **PodDisruptionBudgets (PDB)** son como contratos de alquiler que garantizan que siempre haya un minimo de inquilinos disponibles en el edificio, incluso durante la remodelacion. Si el drain viola esa garantia (por ejemplo, quedan menos Pods de los permitidos), Kubernetes espera en lugar de forzar la evacuacion.

**Terminos nuevos:**
- **scheduling**: el proceso de asignar Pods a nodos
- **SchedulingDisabled**: estado de un nodo que no acepta nuevos Pods
- **PodDisruptionBudget (PDB)**: politica que limita cuantos Pods de una aplicacion pueden estar no disponibles al mismo tiempo
- **DaemonSet**: tipo de recurso que garantiza que un Pod corre en CADA nodo; no se puede evacuar con drain

### Comandos esenciales

```bash
# Cordon: marca nodo como no-schedulable (no mueve pods existentes)
kubectl cordon <node-name>

# Drain: evacua pods del nodo (respeta PodDisruptionBudgets)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Uncordon: restaura scheduling en el nodo
kubectl uncordon <node-name>
```

---

## Area 4: Certificate Management

### Que son los certificados y por que vencen

Los certificados TLS en Kubernetes son como los pasaportes de los componentes del cluster: prueban la identidad de quien se comunica con quien. El API server, el scheduler, el controller manager, y todos los demas componentes se verifican mutuamente usando estos certificados.

Por seguridad, Kubernetes genera certificados con una validez de 1 ano por defecto. Cuando un certificado vence, el componente que lo usa pierde su "pasaporte" y deja de poder comunicarse, lo que puede dejar el cluster inutilizable.

Renovar certificados antes de que venzan es una tarea de mantenimiento rutinaria, similar a renovar el pasaporte antes de un viaje internacional — siempre conviene hacerlo con anticipacion, no el dia que vence.

**Terminos nuevos:**
- **PKI (Public Key Infrastructure)**: sistema de certificados digitales que Kubernetes usa para autenticar componentes
- **CA (Certificate Authority)**: autoridad certificadora, la entidad que firma y valida los certificados
- **x509**: estandar de formato para certificados digitales
- **kubeadm certs**: subcomando de kubeadm para gestionar el ciclo de vida de los certificados

### Comandos esenciales

```bash
# Verificar expiracion de certificados
kubeadm certs check-expiration
```

Salida esperada:

```
CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Mar 01, 2027 12:00 UTC   364d            ca                      no
apiserver                  Mar 01, 2027 12:00 UTC   364d            ca                      no
apiserver-etcd-client      Mar 01, 2027 12:00 UTC   364d            etcd-ca                 no
apiserver-kubelet-client   Mar 01, 2027 12:00 UTC   364d            ca                      no
...
```

La columna `RESIDUAL TIME` muestra cuanto tiempo queda antes de que cada certificado venza. Si ves valores como `30d` o menos, es urgente renovar.

```bash
# Renovar todos los certificados del control plane
kubeadm certs renew all

# Renovar certificado especifico (por ejemplo, solo el del API server)
kubeadm certs renew apiserver

# Ver detalles de un certificado en formato legible
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A2 "Validity"
```

Salida esperada del openssl:

```
        Validity
            Not Before: Mar  1 12:00:00 2025 GMT
            Not After : Mar  1 12:00:00 2026 GMT
```

Estas dos fechas muestran el periodo de validez del certificado. `Not After` es la fecha de vencimiento.

---

## Tabla Comparativa de Comandos

| Area | Comando Principal | Cuando Usarlo | Prioridad CKA |
|------|------------------|---------------|---------------|
| etcd backup | `etcdctl snapshot save` | Antes de cualquier cambio critico | Alta |
| etcd restore | `etcdctl snapshot restore` | Recuperacion ante desastre | Alta |
| Upgrade plan | `kubeadm upgrade plan` | Verificar compatibilidad antes de upgrade | Media |
| Upgrade apply | `kubeadm upgrade apply vX.Y.Z` | Actualizar control plane | Media |
| Cordon | `kubectl cordon <node>` | Impedir scheduling sin mover pods | Alta |
| Drain | `kubectl drain <node>` | Evacuar nodo para mantenimiento | Alta |
| Uncordon | `kubectl uncordon <node>` | Restaurar nodo tras mantenimiento | Alta |
| Check certs | `kubeadm certs check-expiration` | Auditorias periodicas | Media |
| Renew certs | `kubeadm certs renew all` | Certificados proximos a vencer | Media |

---

## Ejercicio Practico (15 min)

### Paso 1: Desplegar recursos (1 min)

Vamos a crear un namespace de prueba con varios Deployments, DaemonSets, y PodDisruptionBudgets para simular un cluster en produccion. Este conjunto de recursos representa una aplicacion web tipica con un servicio critico.

```bash
kubectl apply -f maintenance-lab.yaml
```

Salida esperada:

```
namespace/lab-maintenance-test created
deployment.apps/web-app created
poddisruptionbudget.policy/web-app-pdb created
deployment.apps/critical-service created
poddisruptionbudget.policy/critical-service-pdb created
daemonset.apps/node-agent created
service/web-app-svc created
configmap/test-data created
secret/test-credentials created
```

Cada linea confirma que un recurso fue creado exitosamente. El orden no importa porque Kubernetes gestiona las dependencias internamente.

**¿Que acabamos de aprender?**
Aplicar un archivo YAML con multiples documentos crea todos los recursos en una sola operacion. Kubernetes lee el archivo, valida cada recurso, y los crea de forma concurrente cuando es posible.

### Paso 2: Verificar distribucion de pods (2 min)

Antes de cualquier operacion de mantenimiento, es fundamental saber donde estan corriendo los Pods. Un drain mal planificado puede dejar aplicaciones sin replicas disponibles.

```bash
kubectl get pods -n lab-maintenance-test -o wide
```

Salida esperada (puede variar segun nodos disponibles):

```
NAME                               READY   STATUS    RESTARTS   AGE   NODE
critical-service-xxx-aaa           1/1     Running   0          30s   node1
critical-service-xxx-bbb           1/1     Running   0          30s   node2
critical-service-xxx-ccc           1/1     Running   0          30s   node1
node-agent-xxx                     1/1     Running   0          30s   node1
node-agent-yyy                     1/1     Running   0          30s   node2
web-app-xxx-aaa                    1/1     Running   0          30s   node1
web-app-xxx-bbb                    1/1     Running   0          30s   node2
web-app-xxx-ccc                    1/1     Running   0          30s   node1
web-app-xxx-ddd                    1/1     Running   0          30s   node2
```

La columna `NODE` muestra en que nodo fisico esta cada Pod. Idealmente, los Pods de un mismo Deployment deben estar distribuidos en multiples nodos para sobrevivir el drain de cualquiera de ellos.

Verificar los PodDisruptionBudgets:

```bash
kubectl get pdb -n lab-maintenance-test
```

Salida esperada:

```
NAME                   MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
critical-service-pdb   N/A             1                 1                     45s
web-app-pdb            2               N/A               2                     45s
```

Interpretando esta salida:
- `web-app-pdb` con `MIN AVAILABLE: 2` significa que al menos 2 Pods de `web-app` deben estar disponibles en todo momento. El drain solo puede proceder si despues de evacuar un Pod quedan 2 o mas.
- `critical-service-pdb` con `MAX UNAVAILABLE: 1` significa que como maximo 1 Pod puede estar no disponible al mismo tiempo.
- `ALLOWED DISRUPTIONS` muestra cuantos Pods pueden ser evacuados ahora mismo sin violar el PDB.

**¿Que acabamos de aprender?**
Los PodDisruptionBudgets son contratos de disponibilidad. Antes de drenar un nodo, Kubernetes consulta estos contratos y rechaza la evacuacion si violaria alguno. Esto protege la disponibilidad de las aplicaciones durante el mantenimiento.

### Paso 3: Practicar cordon (2 min)

El cordon es el primer paso cuando preparas un nodo para mantenimiento. Es una operacion no destructiva: no mueve ningun Pod existente, solo impide que nuevos Pods sean programados en ese nodo.

```bash
# Ver nodos disponibles
kubectl get nodes

# Cordonar el nodo (reemplazar <node-name> con el nombre real)
kubectl cordon <node-name>
```

Salida esperada:

```
node/<node-name> cordoned
```

Verificar que el nodo muestra SchedulingDisabled:

```bash
kubectl get nodes
```

Salida esperada:

```
NAME        STATUS                     ROLES           AGE   VERSION
<node>      Ready,SchedulingDisabled   <none>          5d    v1.29.0
```

El estado `Ready,SchedulingDisabled` significa dos cosas al mismo tiempo:
- `Ready`: el nodo esta sano y sus Pods siguen corriendo normalmente
- `SchedulingDisabled`: el scheduler de Kubernetes ignorara este nodo al asignar nuevos Pods

Confirmar que los pods existentes no fueron movidos (solo se impide scheduling de nuevos):

```bash
kubectl get pods -n lab-maintenance-test -o wide
```

Los pods existentes siguen en el nodo cordoned. Solo nuevos pods no se programaran en el.

**¿Que acabamos de aprender?**
El cordon es reversible y seguro. Se usa cuando quieres "congelar" un nodo: dejar de agregarle trabajo sin interrumpir lo que ya tiene. Es el primer paso antes de un drain, pero tambien puede usarse solo si solo quieres prevenir nuevo scheduling temporalmente.

### Paso 4: Practicar drain (3 min)

El drain es la operacion de evacuacion completa. Kubernetes mueve todos los Pods evacuables a otros nodos, respetando los PodDisruptionBudgets. Los Pods del DaemonSet (`node-agent`) son la excepcion: estan disenados para correr en cada nodo y no se pueden mover, por eso se usa el flag `--ignore-daemonsets`.

```bash
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

Salida esperada:

```
node/<node-name> already cordoned
Warning: ignoring DaemonSet-managed Pods: lab-maintenance-test/node-agent-xxx
evicting pod lab-maintenance-test/web-app-xxx-aaa
evicting pod lab-maintenance-test/critical-service-xxx-aaa
pod/web-app-xxx-aaa evicted
pod/critical-service-xxx-aaa evicted
node/<node-name> drained
```

Interpretando esta salida linea por linea:
- `already cordoned`: el nodo ya estaba en modo SchedulingDisabled desde el paso anterior
- `Warning: ignoring DaemonSet-managed Pods`: el Pod `node-agent` fue ignorado intencionalmente porque pertenece a un DaemonSet
- `evicting pod ...`: Kubernetes envio una solicitud de evacuacion a cada Pod
- `pod/... evicted`: el Pod respondio y se termino correctamente
- `node/... drained`: todos los Pods evacuables fueron removidos exitosamente

El flag `--delete-emptydir-data` autoriza a Kubernetes a eliminar datos temporales almacenados en volúmenes de tipo `emptyDir`. Sin este flag, el drain falla si algun Pod usa ese tipo de volumen.

**¿Que acabamos de aprender?**
El drain es una operacion coordinada: Kubernetes no mata los Pods abruptamente, sino que les envia una senal de terminacion y espera a que terminen correctamente (respetando `terminationGracePeriodSeconds`). Los DaemonSets son inmunes al drain porque su proposito es ejecutarse en todos los nodos del cluster.

### Paso 5: Verificar PDB respetado (2 min)

Despues del drain, verificar que los PDB garantizaron la disponibilidad minima durante la evacuacion:

```bash
kubectl get pods -n lab-maintenance-test -o wide
```

Los pods evacuados deben haberse reprogramado en otros nodos disponibles. Si el cluster tiene un solo nodo (Minikube), los pods quedaran en estado `Pending` hasta el uncordon. El estado `Pending` significa que Kubernetes quiere ejecutar el Pod pero no encuentra ningun nodo disponible que acepte scheduling.

Verificar estado de los PDB:

```bash
kubectl describe pdb web-app-pdb -n lab-maintenance-test
```

Salida esperada (fragmento):

```
Name:           web-app-pdb
Namespace:      lab-maintenance-test
Min available:  2
Selector:       app=web-app
Status:
    Allowed disruptions:  2
    Current:              4
    Desired:              2
    Total:                4
Events:         <none>
```

El campo `Current: 4` muestra cuantos Pods del selector `app=web-app` estan disponibles en este momento. `Desired: 2` es el minimo requerido por el PDB. Como `Current >= Desired`, el PDB esta satisfecho y permite mas disrupciones.

**¿Que acabamos de aprender?**
El PDB es un mecanismo de seguridad para el drain: si evacuar un Pod violaria el minimo, Kubernetes pausa la evacuacion y espera a que el Pod sea reprogramado en otro nodo. Esto garantiza que la aplicacion nunca caiga por debajo del umbral de disponibilidad definido.

### Paso 6: Uncordon y verificar (2 min)

Despues de completar el mantenimiento en el nodo (en un escenario real, esto seria la actualizacion de paquetes o el reinicio), se restaura el nodo para que vuelva a aceptar Pods:

```bash
kubectl uncordon <node-name>
```

Salida esperada:

```
node/<node-name> uncordoned
```

Verificar que el nodo volvio a estado Ready:

```bash
kubectl get nodes
```

Salida esperada:

```
NAME        STATUS   ROLES           AGE   VERSION
<node>      Ready    <none>          5d    v1.29.0
```

El estado vuelve a ser simplemente `Ready`, sin `SchedulingDisabled`. Esto significa que el scheduler ya puede asignar nuevos Pods a este nodo.

Los pods que estaban en `Pending` comenzaran a reprogramarse automaticamente en cuestion de segundos:

```bash
kubectl get pods -n lab-maintenance-test -w
```

El flag `-w` (watch) muestra los cambios de estado en tiempo real. Veras como los Pods pasan de `Pending` a `ContainerCreating` y luego a `Running`.

**¿Que acabamos de aprender?**
El ciclo completo `cordon -> drain -> mantenimiento -> uncordon` es la forma estandar y segura de hacer mantenimiento en nodos de produccion. Ninguna aplicacion deberia interrumpirse si los PDB estan bien configurados.

### Paso 7: Verificar datos de prueba (2 min)

Esta verificacion simula lo que harias despues de un restore de etcd: confirmar que los recursos que existian antes del backup siguen existiendo despues del restore. Si el ConfigMap y el Secret estan presentes, significa que el backup capturo el estado correctamente.

```bash
# Verificar ConfigMap
kubectl get configmap test-data -n lab-maintenance-test -o yaml
```

Salida esperada (fragmento):

```yaml
apiVersion: v1
data:
  backup-note: Este ConfigMap sirve para verificar que el backup/restore de etcd
    funciona correctamente
  environment: test
  version: 1.0.0
kind: ConfigMap
metadata:
  name: test-data
  namespace: lab-maintenance-test
```

```bash
# Verificar Secret (los valores aparecen en base64)
kubectl get secret test-credentials -n lab-maintenance-test -o yaml
```

Los Secrets se almacenan en base64 en la API de Kubernetes. Base64 no es cifrado — es solo codificacion para que valores binarios puedan almacenarse como texto. El cifrado real ocurre en etcd si `EncryptionConfiguration` esta habilitado.

```bash
# Decodificar credencial para leer el valor original
kubectl get secret test-credentials -n lab-maintenance-test \
  -o jsonpath='{.data.username}' | base64 -d
```

Salida esperada:

```
admin
```

El valor `admin` es el que se guardo originalmente. El comando extrae el campo `username` del Secret (que esta en base64) y lo pasa al comando `base64 -d` para decodificarlo.

En un escenario real de restore de etcd, la presencia de estos recursos confirma que el backup fue exitoso y el restore funciono correctamente.

**¿Que acabamos de aprender?**
Despues de un restore de etcd, la verificacion mas importante es confirmar que los recursos criticos (Secrets, ConfigMaps, Deployments) existen y tienen los valores correctos. Esta verificacion manual es el equivalente a abrir tus archivos despues de restaurar una copia de seguridad para confirmar que no estan corruptos.

### Paso 8: Limpieza (1 min)

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete namespace lab-maintenance-test
```

---

## Comandos Esenciales CKA

Referencia rapida de los comandos mas evaluados en el examen CKA para el dominio de mantenimiento de clusters:

| Comando | Descripcion | Notas |
|---------|-------------|-------|
| `etcdctl snapshot save <file>` | Backup de etcd | Requiere `--cacert`, `--cert`, `--key` |
| `etcdctl snapshot status <file> --write-out=table` | Verificar backup | Confirma hash y revision |
| `etcdctl snapshot restore <file> --data-dir=<dir>` | Restaurar etcd | Detener API server antes |
| `kubeadm upgrade plan` | Ver versiones disponibles | Muestra compatibilidad |
| `kubeadm upgrade apply vX.Y.Z` | Actualizar control plane | Solo en nodo control plane |
| `kubeadm upgrade node` | Actualizar worker node | Ejecutar en cada worker |
| `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data` | Evacuar nodo | PDB debe permitirlo |
| `kubectl cordon <node>` | Marcar no-schedulable | Sin mover pods existentes |
| `kubectl uncordon <node>` | Restaurar scheduling | Tras finalizar mantenimiento |
| `kubeadm certs check-expiration` | Ver vencimiento de certs | Output en tabla con fechas |
| `kubeadm certs renew all` | Renovar todos los certs | Reiniciar componentes tras renovar |

---

## Checklist de Preparacion CKA

Marcar cada item al completarlo durante el ejercicio:

- [ ] Desplegados todos los recursos con `kubectl apply -f maintenance-lab.yaml`
- [ ] Verificada distribucion de pods con `-o wide`
- [ ] Revisados PodDisruptionBudgets con `kubectl get pdb`
- [ ] Practicado cordon: nodo muestra `SchedulingDisabled`
- [ ] Practicado drain con `--ignore-daemonsets --delete-emptydir-data`
- [ ] Confirmado que DaemonSet permanecio durante drain
- [ ] Verificado que PDB protecio disponibilidad minima
- [ ] Practicado uncordon: nodo vuelve a `Ready`
- [ ] Verificados ConfigMap y Secret como simulacion de post-restore
- [ ] Ejecutado cleanup.sh correctamente

### Conceptos a dominar para el examen

- La diferencia entre `cordon` (no-schedule) y `drain` (evacuacion + no-schedule)
- Por que `--ignore-daemonsets` es necesario en drain
- Como `minAvailable` vs `maxUnavailable` en PDB afectan el drain
- La secuencia correcta para actualizar un cluster con kubeadm
- Los flags requeridos por `etcdctl` (certificados TLS)
- Como verificar la expiracion de certificados y cuando renovar

---

## Referencias a Labs Detallados

| Lab | Tema | Duracion |
|-----|------|----------|
| lab-01-etcd-backup-restore | Backup y restore completo de etcd | 45 min |
| lab-02-cluster-upgrade-minor | Upgrade de version menor con kubeadm | 60 min |
| lab-03-node-drain-cordon | Drain y cordon con PDB en profundidad | 30 min |
| lab-04-certificate-management | Renovacion y gestion de certificados | 45 min |
