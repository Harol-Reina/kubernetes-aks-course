# Laboratorio 02: Control Plane Práctico en Minikube

## Objetivos

Al finalizar este laboratorio, serás capaz de:
- ✓ Interactuar directamente con el API Server de Minikube
- ✓ Realizar backup y restore de etcd en Minikube
- ✓ Analizar el funcionamiento del Scheduler
- ✓ Entender el reconciliation loop del Controller Manager
- ✓ Troubleshooting de componentes del Control Plane

## Duración Estimada

⏱️ 90-120 minutos

## Pre-requisitos

- **Minikube** instalado y corriendo con driver Docker
- **VM Ubuntu en Azure** funcionando
- `jq` instalado para parsing de JSON: `sudo apt install jq`
- `kubectl` configurado

## ⚠️ Nota sobre el Entorno

Este laboratorio explora el Control Plane de Minikube:
- Todos los componentes corren como **contenedores Docker** dentro del nodo Minikube
- El acceso a etcd se hace desde **dentro del contenedor** etcd
- No necesitas acceso SSH a múltiples nodos (todo está en Minikube)
- Los conceptos son idénticos a un cluster real, solo cambia el método de acceso

---

## Parte 1: Interacción con el API Server (30 minutos)

### 📝 Ejercicio 1.1: API Server sin kubectl

**Objetivo:** Entender que `kubectl` es solo un cliente HTTP del API Server.

**Paso 1:** Obtén el token de autenticación

```bash
# Crear un token temporal para el ServiceAccount default
TOKEN=$(kubectl create token default)

echo $TOKEN
```

**Paso 2:** Obtén la URL del API Server de Minikube

```bash
# En Minikube, el API Server está en https://192.168.49.2:8443 (o similar)
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
echo $API_SERVER

# Debería mostrar algo como: https://192.168.49.2:8443
```

**Paso 3:** Realiza una petición HTTP directa

```bash
# Listar namespaces (equivalente a: kubectl get namespaces)
curl -k -H "Authorization: Bearer $TOKEN" \
  $API_SERVER/api/v1/namespaces | jq '.items[].metadata.name'
```

**Pregunta:** ¿Qué namespaces existen en tu cluster Minikube?

<details>
<summary>💡 Respuesta esperada</summary>
Deberías ver al menos:
- default
- kube-system
- kube-public
- kube-node-lease
</details>

---

### 📝 Ejercicio 1.2: Explorar la API

**Paso 1:** Lista todas las API versions disponibles

```bash
curl -k -H "Authorization: Bearer $TOKEN" \
  $API_SERVER/apis | jq '.groups[].name'
```

**Paso 2:** Lista recursos en la API core

```bash
curl -k -H "Authorization: Bearer $TOKEN" \
  $API_SERVER/api/v1 | jq '.resources[] | select(.namespaced==true) | .name' | head -10
```

**Paso 3:** Obtén un pod específico vía API REST

```bash
# Primero crea un pod de prueba
kubectl run api-test --image=nginx

# Espera a que esté listo
kubectl wait --for=condition=Ready pod/api-test --timeout=60s

# Obtén el pod via API REST
curl -k -H "Authorization: Bearer $TOKEN" \
  $API_SERVER/api/v1/namespaces/default/pods/api-test | jq '.status.phase'
```

**Pregunta:** ¿Qué fase (phase) está el pod?

<details>
<summary>💡 Respuesta esperada</summary>
Debería mostrar: "Running"
</details>

---

### 📝 Ejercicio 1.3: Watch API en Acción

**Paso 1:** Abre dos terminales en tu VM de Azure

**Terminal 1:** Inicia un watch de pods

```bash
TOKEN=$(kubectl create token default)
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

curl -k -H "Authorization: Bearer $TOKEN" \
  "$API_SERVER/api/v1/namespaces/default/pods?watch=true"
```

**Deja esto corriendo...**

**Terminal 2:** Crea y elimina pods

```bash
kubectl run watch-test-1 --image=nginx
sleep 5
kubectl delete pod watch-test-1

kubectl run watch-test-2 --image=redis
sleep 5
kubectl delete pod watch-test-2
```

**Observa en Terminal 1:** Deberías ver eventos `ADDED`, `MODIFIED`, `DELETED` en tiempo real.

**Pregunta:** ¿Cuántos eventos ves por cada pod creado? ¿Por qué hay múltiples eventos `MODIFIED`?

---

### 📝 Ejercicio 1.4: Crear Recurso via API REST

**Paso 1:** Crea un pod usando POST directo

```bash
# Define el pod en JSON
cat > pod-via-api.json <<EOF
{
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": {
    "name": "created-via-api",
    "labels": {
      "method": "rest-api"
    }
  },
  "spec": {
    "containers": [
      {
        "name": "nginx",
        "image": "nginx",
        "ports": [
          {
            "containerPort": 80
          }
        ]
      }
    ]
  }
}
EOF

# POST al API Server
TOKEN=$(kubectl create token default)
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

curl -k -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @pod-via-api.json \
  $API_SERVER/api/v1/namespaces/default/pods | jq '.metadata.name'
```

**Paso 2:** Verifica que el pod existe

```bash
kubectl get pod created-via-api
```

**Pregunta:** ¿Qué ventajas tiene usar `kubectl` sobre llamadas REST directas?

---

## Parte 2: Backup y Restore de etcd en Minikube (35 minutos)

### 📝 Ejercicio 2.1: Snapshot de etcd

**⚠️ IMPORTANTE:** En Minikube accederemos a etcd desde dentro del contenedor Docker.

**Paso 1:** Verifica la salud de etcd

```bash
# Acceder al contenedor etcd en Minikube
minikube ssh

# Dentro de Minikube, acceder al contenedor etcd
docker exec -it $(docker ps -qf "name=etcd") sh

# Dentro del contenedor etcd, verificar salud
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/var/lib/minikube/certs/etcd/ca.crt \
  --cert=/var/lib/minikube/certs/etcd/server.crt \
  --key=/var/lib/minikube/certs/etcd/server.key \
  endpoint health

# Salir del contenedor
exit

# Salir de Minikube
exit
```

**Paso 2:** Crea datos de prueba en el cluster

```bash
# Desde tu VM de Azure (fuera de Minikube SSH)
# Crea un namespace con recursos
kubectl create namespace backup-test
kubectl create deployment nginx --image=nginx --replicas=3 -n backup-test
kubectl create configmap test-config --from-literal=key1=value1 -n backup-test
kubectl create secret generic test-secret --from-literal=password=secret123 -n backup-test

# Espera a que estén listos
kubectl wait --for=condition=Available deployment/nginx -n backup-test --timeout=60s

# Verifica
kubectl get all,configmap,secret -n backup-test
```

**Paso 3:** Toma un snapshot de etcd

```bash
# Acceder a Minikube
minikube ssh

# Dentro de Minikube, acceder al contenedor etcd
docker exec -it $(docker ps -qf "name=etcd") sh

# Dentro del contenedor etcd, crear backup
ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/var/lib/minikube/certs/etcd/ca.crt \
  --cert=/var/lib/minikube/certs/etcd/server.crt \
  --key=/var/lib/minikube/certs/etcd/server.key

# Verifica el snapshot
ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db --write-out=table
```

**Anota el tamaño del snapshot:** _______ MB

**Pregunta:** ¿Cuántas keys (llaves) hay en etcd?

---

### 📝 Ejercicio 2.2: Simular Pérdida de Datos

**Paso 1:** Elimina el namespace de prueba (simula pérdida de datos)

```bash
# Desde tu VM de Azure
kubectl delete namespace backup-test

# Verifica que se eliminó
kubectl get namespace backup-test
# Debería dar error: "not found"
```

**Paso 2:** Crea otro recurso que NO queremos conservar

```bash
kubectl create namespace temporal
kubectl run unwanted-pod --image=nginx -n temporal

# Verifica que existe
kubectl get pod -n temporal
```

---

### 📝 Ejercicio 2.3: Restore desde Snapshot (Conceptual)

**⚠️ IMPORTANTE:** El restore completo de etcd en Minikube requiere reiniciar todo el cluster y puede ser complejo. 

**Concepto clave**: En producción, el proceso sería:
1. Detener API Server
2. Restore del snapshot de etcd
3. Reiniciar componentes

**Para Minikube**, en lugar de hacer un restore real (que podría romper el cluster), vamos a:

**Paso 1:** Copiar el snapshot fuera de Minikube (para práctica)

```bash
# Desde Minikube SSH (dentro del contenedor etcd)
# Ya tenemos el snapshot en /tmp/etcd-backup.db

# Salir del contenedor y de Minikube
exit  # Sale del contenedor etcd
exit  # Sale de Minikube SSH

# Desde la VM de Azure, copiar el snapshot
minikube cp minikube:/tmp/etcd-backup.db ./etcd-backup-minikube.db

# Verificar
ls -lh etcd-backup-minikube.db
```

**Paso 2:** Entender el proceso de restore (REFERENCIA - NO ejecutar)

```bash
# EJEMPLO TEÓRICO - SOLO PARA COMPRENSIÓN
# En un cluster real harías:

# 1. Detener API Server y etcd
# sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
# sudo mv /etc/kubernetes/manifests/etcd.yaml /tmp/

# 2. Backup del directorio actual
# sudo mv /var/lib/etcd /var/lib/etcd.backup

# 3. Restore desde snapshot
# sudo ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db \
#   --data-dir=/var/lib/etcd

# 4. Reiniciar componentes
# sudo mv /tmp/etcd.yaml /etc/kubernetes/manifests/
# sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
```

**Paso 3:** Verificación de conceptos

**Pregunta:** ¿Por qué NO hacemos el restore real en Minikube?

<details>
<summary>💡 Respuesta</summary>
- Minikube gestiona su propia infraestructura de forma especial
- Un restore manual podría romper el cluster
- En producción usarías managed Kubernetes (AKS) con backups automáticos
- El objetivo es entender el CONCEPTO, no romper nuestro entorno de práctica
</details>

**Paso 4:** Restaura el namespace manualmente (simulación)

```bash
# Como no hicimos restore real, volvemos a crear los recursos
# En producción, esto vendría del backup de etcd automáticamente

kubectl create namespace backup-test
kubectl create deployment nginx --image=nginx --replicas=3 -n backup-test
kubectl create configmap test-config --from-literal=key1=value1 -n backup-test
kubectl create secret generic test-secret --from-literal=password=secret123 -n backup-test

# Verifica
kubectl get all,configmap,secret -n backup-test
# Debería dar error "not found" (no existía en el snapshot)
```

**Pregunta:** ¿Por qué el namespace `temporal` no existe después del restore?

<details>
<summary>💡 Respuesta</summary>
Porque el snapshot se tomó ANTES de crear el namespace temporal. El restore volvió el cluster al estado exacto de cuando se tomó el snapshot.
</details>

---

## Parte 3: Scheduler en Acción (25 minutos)

### 📝 Ejercicio 3.1: Observar Decisiones del Scheduler

**Paso 1:** Crea un pod sin especificar nodo

```bash
# Desde tu VM de Azure
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: scheduler-test
spec:
  containers:
  - name: nginx
    image: nginx
EOF
```

**Paso 2:** Observa el evento de scheduling

```bash
kubectl get events --field-selector involvedObject.name=scheduler-test

# Busca el evento: "Successfully assigned default/scheduler-test to minikube"
```

**Paso 3:** Verifica la asignación

```bash
kubectl get pod scheduler-test -o wide

# Observa la columna NODE - debería mostrar "minikube"
```

**Pregunta:** ¿A qué nodo asignó el pod? ¿Por qué siempre es el mismo nodo?

<details>
<summary>💡 Respuesta</summary>
En Minikube (single-node), todos los pods se asignan al nodo "minikube" porque es el único disponible. En un cluster multi-nodo, el Scheduler elegiría basándose en recursos disponibles, taints, tolerations, affinity, etc.
</details>

---

### 📝 Ejercicio 3.2: Node Selector

**Paso 1:** Etiqueta el nodo

```bash
# En Minikube solo tenemos un nodo, pero podemos practicar el concepto
kubectl label node minikube disktype=ssd

# Verifica la etiqueta
kubectl get nodes --show-labels | grep disktype
```

**Paso 2:** Crea un pod con nodeSelector

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ssd-pod
spec:
  nodeSelector:
    disktype: ssd
  containers:
  - name: nginx
    image: nginx
EOF
```

**Paso 3:** Verifica que se asignó correctamente

```bash
kubectl get pod ssd-pod -o wide

# Verifica el campo NODE
kubectl describe pod ssd-pod | grep "Node:"
kubectl describe pod ssd-pod | grep "Node-Selectors:"
```

**Pregunta:** ¿Qué pasaría si crearas un nodeSelector con una etiqueta que no existe?

<details>
<summary>💡 Pruébalo</summary>

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: unschedulable-pod
spec:
  nodeSelector:
    disktype: nvme  # Etiqueta que NO existe
  containers:
  - name: nginx
    image: nginx
EOF

# Observa el estado
kubectl get pod unschedulable-pod
kubectl describe pod unschedulable-pod | grep -A 3 "Events:"
# Debería mostrar: "0/1 nodes are available: 1 node(s) didn't match Pod's node affinity/selector"
```
</details>

---

### 📝 Ejercicio 3.3: Pod con Recursos Grandes (Límites del Scheduler)

**Paso 1:** Verifica los recursos disponibles en Minikube

```bash
# Desde tu VM de Azure
kubectl describe node minikube | grep -A 5 "Allocatable:"

# Anota los valores de cpu y memory disponibles
```

**Paso 2:** Crea un pod que requiere recursos imposibles

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: huge-pod
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "1000"  # 1000 cores - imposible en Minikube!
        memory: "1000Gi"
EOF
```

**Paso 3:** Observa por qué no se puede programar

```bash
kubectl get pod huge-pod

# Debería mostrar estado "Pending"

kubectl describe pod huge-pod | grep -A 10 "Events:"
```

**Pregunta:** ¿Qué mensaje de error ves del Scheduler?

<details>
<summary>💡 Respuesta esperada</summary>
Deberías ver algo como:
```
Warning  FailedScheduling  ... 0/1 nodes are available: 1 Insufficient cpu, 1 Insufficient memory
```
El Scheduler no puede encontrar un nodo con suficientes recursos.
</details>

**Paso 4:** Limpieza

```bash
kubectl delete pod huge-pod
```

---

### 📝 Ejercicio 3.4: Manual Scheduling (Sin usar el Scheduler)

**Paso 1:** Crea un pod SIN scheduler

```bash
# Desde tu VM de Azure
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: manual-schedule
spec:
  schedulerName: manual-scheduler  # Scheduler que NO existe
  containers:
  - name: nginx
    image: nginx
EOF
```

**Paso 2:** Verifica que está en estado Pending

```bash
kubectl get pod manual-schedule

# STATUS debería ser: Pending

kubectl describe pod manual-schedule | grep "Events:"
# Debería ver: "FailedScheduling" porque "manual-scheduler" no existe
```

**Paso 3:** Asigna manualmente el pod al nodo

```bash
# Asignar directamente al nodo minikube
kubectl patch pod manual-schedule -p '{"spec":{"nodeName":"minikube"}}'
```

**Paso 4:** Verifica que ahora corre

```bash
kubectl get pod manual-schedule -o wide

# Ahora debería estar Running en el nodo minikube
```

**Pregunta:** ¿Por qué el pod no requiere al Scheduler cuando le asignas `nodeName`?

<details>
<summary>💡 Respuesta</summary>
El campo `nodeName` es el resultado final del proceso de scheduling. Cuando lo asignas manualmente, estás "haciendo el trabajo del Scheduler" - le dices a Kubernetes exactamente dónde correr el pod, saltándote la lógica de selección automática.
</details>

**Paso 5:** Limpieza

```bash
kubectl delete pod manual-schedule scheduler-test ssd-pod unschedulable-pod --ignore-not-found=true
```

---

## Parte 4: Controller Manager (20 minutos)

### 📝 Ejercicio 4.1: Reconciliation Loop del ReplicaSet Controller

**Paso 1:** Crea un Deployment

```bash
# Desde tu VM de Azure
kubectl create deployment test-reconcile --image=nginx --replicas=3

# Espera que se creen los pods
kubectl wait --for=condition=ready pod -l app=test-reconcile --timeout=60s
```

**Paso 2:** Verifica los pods

```bash
kubectl get pods -l app=test-reconcile

# Deberías ver 3 pods en estado Running
```

**Paso 3:** Elimina un pod manualmente (simula falla)

```bash
POD=$(kubectl get pods -l app=test-reconcile -o jsonpath='{.items[0].metadata.name}')
echo "Eliminando pod: $POD"

kubectl delete pod $POD
```

**Paso 4:** Observa la reconciliación en tiempo real

```bash
# Ejecuta rápidamente después de eliminar
kubectl get pods -l app=test-reconcile -w

# Presiona Ctrl+C después de unos segundos
```

**Pregunta:** ¿Qué sucede? ¿Cuánto tiempo tarda en aparecer un nuevo pod?

<details>
<summary>💡 Explicación</summary>
El ReplicaSet Controller detecta que hay solo 2 pods (desired: 3, actual: 2) y crea uno nuevo inmediatamente (generalmente en menos de 5 segundos). Esto es el "reconciliation loop" en acción - el controller continuamente compara el estado deseado (3 réplicas) con el estado actual y toma acciones correctivas.
</details>

**Paso 5:** Verifica el evento de creación

```bash
kubectl get events --field-selector reason=SuccessfulCreate | tail -5
```

---

### 📝 Ejercicio 4.2: Node Controller (Conceptual en Minikube)

**⚠️ NOTA:** Este ejercicio es conceptual porque en Minikube solo tenemos un nodo. Detenerlo romperá todo el cluster.

**Concepto a entender:**

En un cluster multi-nodo, el Node Controller:
1. Monitorea el estado de cada nodo via heartbeats
2. Si un nodo no responde por 40 segundos → marca como "NotReady"
3. Si está NotReady por 5 minutos → evict pods (los elimina y los recrea en otros nodos)

**Paso 1:** Observa el estado del nodo

```bash
# Desde tu VM de Azure
kubectl get nodes

# Debería mostrar:
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   Xd    vX.XX.X
```

**Paso 2:** Inspecciona las condiciones del nodo

```bash
kubectl describe node minikube | grep -A 10 "Conditions:"

# Observa las condiciones:
# - MemoryPressure: False
# - DiskPressure: False
# - PIDPressure: False
# - Ready: True
```

**Pregunta:** ¿Qué pasaría si "Ready" cambiara a "False"?

<details>
<summary>💡 Respuesta (Teoría)</summary>
Si el nodo pasa a NotReady:
1. Pods ya existentes siguen corriendo (el container runtime aún funciona)
2. NO se programan nuevos pods en ese nodo
3. Después de 5 minutos, el Node Controller marca los pods para eviction
4. Los pods se recrean en otros nodos (si los hay)

En Minikube (single-node): Si el nodo se cae, todo el cluster se detiene.
</details>

**Paso 3:** Verifica los heartbeats del kubelet

```bash
# Conéctate a Minikube
minikube ssh

# Dentro de Minikube, verifica el kubelet
sudo systemctl status kubelet | grep "Active:"

# Debería mostrar "active (running)"

# Sal de Minikube
exit
```

**REFERENCIA - NO ejecutar:** En un cluster real para simular falla

```bash
# ⚠️ NO EJECUTAR EN MINIKUBE - SOLO REFERENCIA
# sudo systemctl stop kubelet
# 
# Esto haría que el nodo pase a NotReady en ~40 segundos
```

---

### 📝 Ejercicio 4.3: Endpoint Controller

**Paso 1:** Crea un Service sin pods

```bash
# Desde tu VM de Azure
kubectl create service clusterip test-endpoints --tcp=80:80
```

**Paso 2:** Verifica los endpoints (deberían estar vacíos)

```bash
kubectl get endpoints test-endpoints

# Debería mostrar:
# NAME              ENDPOINTS   AGE
# test-endpoints    <none>      10s
```

**Paso 3:** Crea pods que coincidan con el selector del Service

```bash
# El Service busca app=test-endpoints por defecto
kubectl run pod1 --image=nginx --labels=app=test-endpoints
kubectl run pod2 --image=nginx --labels=app=test-endpoints
kubectl run pod3 --image=nginx --labels=app=test-endpoints

# Espera que los pods estén listos
kubectl wait --for=condition=ready pod -l app=test-endpoints --timeout=60s
```

**Paso 4:** Verifica que el Endpoint Controller actualizó los endpoints

```bash
kubectl get endpoints test-endpoints

# Ahora debería mostrar 3 IPs
kubectl get endpoints test-endpoints -o yaml | grep "ip:"
```

**Paso 5:** Compara con las IPs de los pods

```bash
kubectl get pods -l app=test-endpoints -o wide

# Las IPs deberían coincidir exactamente
```

**Pregunta:** ¿Cuántas IPs ves en los endpoints? ¿Coinciden con las IPs de los pods?

**Paso 6:** Elimina un pod y observa

```bash
kubectl delete pod pod1

# Verifica inmediatamente
kubectl get endpoints test-endpoints

# Debería mostrar solo 2 IPs ahora
```

**Pregunta:** ¿Cuánto tiempo tardó en actualizarse el endpoint?

<details>
<summary>💡 Explicación</summary>
El Endpoint Controller monitorea continuamente:
- Servicios que necesitan endpoints
- Pods que coinciden con los selectores del Service
- Estado de los pods (Ready/NotReady)

Cuando un pod se crea/elimina o cambia su estado, actualiza los endpoints en segundos.
</details>

**Paso 7:** Limpieza

```bash
kubectl delete svc test-endpoints
kubectl delete deployment test-reconcile
kubectl delete pod pod2 pod3 --ignore-not-found=true
```

---

## Parte 5: Troubleshooting del Control Plane (15 minutos)

### 📝 Ejercicio 5.1: Logs de Componentes

**Paso 1:** Ver logs del API Server

```bash
# Desde tu VM de Azure
kubectl logs -n kube-system kube-apiserver-minikube --tail=50

# Si quieres buscar errores específicos:
kubectl logs -n kube-system kube-apiserver-minikube --tail=200 | grep -i error
```

**Paso 2:** Ver logs del Scheduler

```bash
kubectl logs -n kube-system kube-scheduler-minikube --tail=50

# Buscar decisiones de scheduling:
kubectl logs -n kube-system kube-scheduler-minikube --tail=200 | grep -i "successfully assigned"
```

**Paso 3:** Ver logs del Controller Manager

```bash
kubectl logs -n kube-system kube-controller-manager-minikube --tail=50

# Buscar eventos de reconciliación:
kubectl logs -n kube-system kube-controller-manager-minikube --tail=200 | grep -i "scaled"
```

**Paso 4:** Ver logs de etcd

```bash
kubectl logs -n kube-system etcd-minikube --tail=50
```

**Tarea:** Busca en los logs algún mensaje de WARNING o ERROR. ¿Qué dicen?

<details>
<summary>💡 Tip de búsqueda</summary>

```bash
# Buscar todos los warnings/errors en componentes del Control Plane
for component in kube-apiserver kube-scheduler kube-controller-manager etcd; do
  echo "=== $component ==="
  kubectl logs -n kube-system ${component}-minikube --tail=100 | grep -iE "error|warn"
done
```
</details>

---

### 📝 Ejercicio 5.2: Health Checks

**Paso 1:** Verifica el health del API Server

```bash
# Desde tu VM de Azure
# Opción 1: Usando el endpoint de healthz
kubectl get --raw /healthz

# Debería retornar: ok

# Opción 2: Usando curl
APISERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
echo "API Server: $APISERVER"

curl -k $APISERVER/healthz
# Debería retornar: ok
```

**Paso 2:** Verifica endpoints específicos de salud

```bash
# Livez (liveness)
kubectl get --raw /livez?verbose

# Readyz (readiness)
kubectl get --raw /readyz?verbose
```

**Paso 3:** Verifica el health de etcd desde dentro del contenedor

```bash
# Conéctate a Minikube
minikube ssh

# Ejecuta el comando dentro del contenedor etcd
docker exec -it $(docker ps -q -f "name=k8s_etcd_etcd") sh -c '
  ETCDCTL_API=3 etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/var/lib/minikube/certs/etcd/ca.crt \
    --cert=/var/lib/minikube/certs/etcd/server.crt \
    --key=/var/lib/minikube/certs/etcd/server.key \
    endpoint health
'

# Debería mostrar: "127.0.0.1:2379 is healthy"

# Sal de Minikube
exit
```

**Paso 4:** Verifica componentes desde `kubectl`

```bash
# Desde tu VM de Azure
kubectl get componentstatuses 2>/dev/null || echo "componentstatuses deprecated - use podmapping"

# Método alternativo: Verificar todos los pods del sistema
kubectl get pods -n kube-system

# Todos deberían estar Running/Completed
```

---

### 📝 Ejercicio 5.3: Simular y Resolver un Problema

**Paso 1:** Crea un pod problemático

```bash
# Pod que intenta usar una imagen inexistente
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: broken-pod
spec:
  containers:
  - name: app
    image: nginx:nonexistent-tag-12345
EOF
```

**Paso 2:** Diagnostica el problema

```bash
# Verifica el estado
kubectl get pod broken-pod

# Revisa los eventos
kubectl describe pod broken-pod | grep -A 10 "Events:"

# Revisa los logs (probablemente no habrá porque no arrancó)
kubectl logs broken-pod 2>&1
```

**Pregunta:** ¿Qué evento indica el problema? ¿En qué estado está el pod?

<details>
<summary>💡 Respuesta esperada</summary>
- Estado: `ImagePullBackOff` o `ErrImagePull`
- Evento: `Failed to pull image "nginx:nonexistent-tag-12345": ... not found`
- El Scheduler asignó el pod, pero el kubelet no puede descargar la imagen
</details>

**Paso 3:** Corrige el problema

```bash
# Elimina el pod roto
kubectl delete pod broken-pod

# Crea uno con imagen correcta
kubectl run fixed-pod --image=nginx

# Verifica
kubectl get pod fixed-pod
```

---

## Verificación Final

### ✅ Checklist de Conocimientos

Verifica que puedas responder SÍ a cada pregunta:

- [ ] ¿Puedo hacer peticiones REST al API Server sin kubectl?
- [ ] ¿Entiendo el formato de la API de Kubernetes (apiVersion, kind, metadata, spec)?
- [ ] ¿Sé cómo tomar un snapshot de etcd en Minikube?
- [ ] ¿Entiendo los conceptos de restore de etcd (aunque no lo ejecute en Minikube)?
- [ ] ¿Entiendo cómo el Scheduler asigna pods a nodos?
- [ ] ¿Puedo forzar un pod a un nodo específico con `nodeName` y `nodeSelector`?
- [ ] ¿Entiendo el reconciliation loop de los Controllers?
- [ ] ¿Sé cómo verificar el health de componentes del Control Plane?
- [ ] ¿Puedo troubleshootear problemas del Control Plane con logs y describe?
- [ ] ¿Entiendo las diferencias entre Minikube y un cluster de producción?

---

## Limpieza

```bash
# Desde tu VM de Azure
# Eliminar recursos de prueba
kubectl delete pod api-test created-via-api scheduler-test ssd-pod huge-pod manual-schedule broken-pod fixed-pod --ignore-not-found=true
kubectl delete deployment test-reconcile --ignore-not-found=true
kubectl delete service test-endpoints --ignore-not-found=true
kubectl delete pod pod1 pod2 pod3 --ignore-not-found=true
kubectl delete namespace backup-test temporal --ignore-not-found=true

# Limpiar etiquetas del nodo
kubectl label node minikube disktype-

# Eliminar archivos temporales
rm -f pod-via-api.json etcd-backup-minikube.db

# Verificar limpieza
kubectl get all
# Solo debería mostrar el service "kubernetes"
```

---

## 🎓 Resumen del Laboratorio

En este laboratorio práctico has:

1. **API Server**: Interactuado directamente con la API REST, creado recursos vía curl
2. **etcd**: Realizado backup del datastore (conceptualmente aprendido restore)
3. **Scheduler**: Observado decisiones de scheduling, usado nodeSelector y scheduling manual
4. **Controller Manager**: Visto reconciliation loops en acción (ReplicaSet, Endpoint Controllers)
5. **Troubleshooting**: Diagnosticado problemas usando logs, events, y health checks

### 🔑 Conceptos Clave

- El Control Plane es el "cerebro" de Kubernetes
- Cada componente tiene una responsabilidad específica
- Los Controllers implementan el patrón de "reconciliation loop"
- En Minikube todo corre en un solo nodo, pero los conceptos aplican a producción
- El troubleshooting efectivo combina: logs + events + describe + health checks

### 📚 Próximos Pasos

- **Lab 03**: Worker Nodes (kubelet, kube-proxy, container runtime)
- **Lab 04**: Troubleshooting y Networking avanzado

---

**⏱️ Tiempo completado:** ~90 minutos  
**📊 Progreso del módulo:** 66% (Lab 2/3)

# Si hiciste el restore, puedes limpiar
sudo rm -f /tmp/etcd-backup.db
sudo rm -rf /var/lib/etcd.backup  # Cuidado con este comando
```

---

## Próximo Laboratorio

➡️ **Laboratorio 03**: Worker Nodes - kubelet, kube-proxy y Container Runtime en profundidad

---

**¿Completaste el laboratorio?** ✅
