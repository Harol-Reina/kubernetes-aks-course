# Resumen Rapido: Cluster Maintenance & Upgrades

**Duracion:** 15 minutos | **Nivel:** Repaso | **Archivo:** `maintenance-lab.yaml`

Resumen practico de las 4 areas clave de mantenimiento de clusters Kubernetes cubiertas en el Modulo 23: etcd backup/restore, cluster upgrades, node drain/cordon, y gestion de certificados.

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

### Area 1: etcd Backup/Restore

El datastore etcd almacena todo el estado del cluster. Un backup previo a cualquier operacion de mantenimiento es obligatorio en produccion.

Comandos esenciales:

```bash
# Backup de etcd
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verificar backup
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd-snapshot.db --write-out=table

# Restore (ejecutar en nodo control plane, detener API server primero)
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db \
  --data-dir=/var/lib/etcd-restored
```

### Area 2: Cluster Upgrade

Proceso estandar con kubeadm para actualizar version menor (e.g., 1.28 -> 1.29):

```bash
# Control plane
apt-get install -y kubeadm=1.29.0-1.1
kubeadm upgrade plan
kubeadm upgrade apply v1.29.0
apt-get install -y kubelet=1.29.0-1.1 kubectl=1.29.0-1.1
systemctl restart kubelet

# Worker nodes (repetir por cada nodo)
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
# [en el nodo]: apt-get install -y kubeadm=1.29.0-1.1 kubelet=1.29.0-1.1
# [en el nodo]: kubeadm upgrade node && systemctl restart kubelet
kubectl uncordon <node>
```

### Area 3: Node Drain/Cordon

Mecanismo de evacuacion controlada de workloads antes de mantenimiento de nodo.

```bash
# Cordon: marca nodo como no-schedulable (no mueve pods existentes)
kubectl cordon <node-name>

# Drain: evacua pods del nodo (respeta PodDisruptionBudgets)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Uncordon: restaura scheduling en el nodo
kubectl uncordon <node-name>
```

### Area 4: Certificate Management

Kubernetes genera certificados con validez de 1 anio por defecto.

```bash
# Verificar expiracion de certificados
kubeadm certs check-expiration

# Renovar todos los certificados del control plane
kubeadm certs renew all

# Renovar certificado especifico
kubeadm certs renew apiserver

# Ver detalles de un certificado
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A2 "Validity"
```

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

### Paso 2: Verificar distribucion de pods (2 min)

Confirmar que los pods estan distribuidos y los PDB estan activos:

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

### Paso 3: Practicar cordon (2 min)

Seleccionar un nodo worker para simular mantenimiento. En un cluster de un solo nodo (Minikube), usar el nodo disponible con precaucion:

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

Confirmar que los pods existentes no fueron movidos (solo se impide scheduling de nuevos):

```bash
kubectl get pods -n lab-maintenance-test -o wide
```

Los pods existentes siguen en el nodo cordoned. Solo nuevos pods no se programaran en el.

### Paso 4: Practicar drain (3 min)

El drain evacua los pods del nodo respetando los PodDisruptionBudgets:

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

Nota: El flag `--ignore-daemonsets` es necesario porque los DaemonSets (node-agent) no pueden ser evacuados - estan disenados para correr en todos los nodos.

### Paso 5: Verificar PDB respetado (2 min)

Verificar que los PDB garantizaron disponibilidad minima durante el drain:

```bash
kubectl get pods -n lab-maintenance-test -o wide
```

Los pods evacuados deben haberse reprogramado en otros nodos disponibles. Si el cluster tiene un solo nodo (Minikube), los pods quedaran en estado Pending hasta el uncordon.

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

### Paso 6: Uncordon y verificar (2 min)

Restaurar el nodo para que acepte nuevos pods:

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

Los pods que estaban en Pending comenzaran a reprogramarse:

```bash
kubectl get pods -n lab-maintenance-test -w
```

### Paso 7: Verificar datos de prueba (2 min)

Simular verificacion post-restore: confirmar que ConfigMap y Secret persisten correctamente.

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

```bash
# Decodificar credencial
kubectl get secret test-credentials -n lab-maintenance-test \
  -o jsonpath='{.data.username}' | base64 -d
```

Salida esperada:

```
admin
```

En un escenario real de restore de etcd, la presencia de estos recursos confirma que el backup fue exitoso y el restore funciono correctamente.

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
