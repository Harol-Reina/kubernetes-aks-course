# Laboratorio 02: Control Plane Práctico

## Objetivos

Al finalizar este laboratorio, serás capaz de:
- ✓ Interactuar directamente con el API Server
- ✓ Realizar backup y restore de etcd
- ✓ Analizar el funcionamiento del Scheduler
- ✓ Entender el reconciliation loop del Controller Manager
- ✓ Troubleshooting de componentes del Control Plane

## Duración Estimada

⏱️ 90-120 minutos

## Pre-requisitos

- Cluster Kubernetes con acceso al Control Plane
- Herramienta `etcdctl` instalada
- Acceso SSH a nodos master
- `jq` instalado para parsing de JSON
- Permisos de administrador

---

## Parte 1: Interacción con el API Server (30 minutos)

### 📝 Ejercicio 1.1: API Server sin kubectl

**Objetivo:** Entender que `kubectl` es solo un cliente HTTP del API Server.

**Paso 1:** Obtén el token de autenticación

```bash
# Obtener token del ServiceAccount por defecto
TOKEN=$(kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].data.token}" | base64 --decode)

# O crear un token temporal
TOKEN=$(kubectl create token default)

echo $TOKEN
```

**Paso 2:** Obtén la URL del API Server

```bash
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
echo $API_SERVER
```

**Paso 3:** Realiza una petición HTTP directa

```bash
# Listar namespaces (equivalente a: kubectl get namespaces)
curl -k -H "Authorization: Bearer $TOKEN" \
  $API_SERVER/api/v1/namespaces | jq '.items[].metadata.name'
```

**Pregunta:** ¿Qué namespaces existen en tu cluster?

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

**Paso 3:** Obtén un pod específico

```bash
# Primero crea un pod de prueba
kubectl run api-test --image=nginx

# Espera a que esté listo
kubectl wait --for=condition=Ready pod/api-test

# Obtén el pod via API
curl -k -H "Authorization: Bearer $TOKEN" \
  $API_SERVER/api/v1/namespaces/default/pods/api-test | jq '.status.phase'
```

**Pregunta:** ¿Qué fase (phase) está el pod?

---

### 📝 Ejercicio 1.3: Watch API en Acción

**Paso 1:** Abre dos terminales

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

## Parte 2: Backup y Restore de etcd (35 minutos)

### 📝 Ejercicio 2.1: Snapshot de etcd

**⚠️ IMPORTANTE:** Este ejercicio requiere acceso SSH al nodo master.

**Paso 1:** Verifica la salud de etcd

```bash
# Desde el nodo master
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
```

**Paso 2:** Crea datos de prueba en el cluster

```bash
# Crea un namespace con recursos
kubectl create namespace backup-test
kubectl create deployment nginx --image=nginx --replicas=3 -n backup-test
kubectl create configmap test-config --from-literal=key1=value1 -n backup-test
kubectl create secret generic test-secret --from-literal=password=secret123 -n backup-test

# Verifica
kubectl get all,configmap,secret -n backup-test
```

**Paso 3:** Toma un snapshot de etcd

```bash
# Desde el nodo master
sudo ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verifica el snapshot
sudo ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db --write-out=table
```

**Anota el tamaño del snapshot:** _______ MB

---

### 📝 Ejercicio 2.2: Simular Pérdida de Datos

**Paso 1:** Elimina el namespace de prueba

```bash
kubectl delete namespace backup-test

# Verifica que se eliminó
kubectl get namespace backup-test
# Debería dar error: "not found"
```

**Paso 2:** Crea otro recurso que NO queremos conservar

```bash
kubectl create namespace temporal
kubectl run unwanted-pod --image=nginx -n temporal
```

---

### 📝 Ejercicio 2.3: Restore desde Snapshot

**⚠️ CRÍTICO:** Esto detendrá el cluster temporalmente.

**Paso 1:** Detén el API Server y etcd

```bash
# Desde el nodo master
sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sudo mv /etc/kubernetes/manifests/etcd.yaml /tmp/

# Espera 30 segundos a que se detengan los pods
sleep 30

# Verifica que etcd no está corriendo
ps aux | grep etcd
```

**Paso 2:** Backup del directorio actual de etcd

```bash
sudo mv /var/lib/etcd /var/lib/etcd.backup
```

**Paso 3:** Restore desde el snapshot

```bash
sudo ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db \
  --data-dir=/var/lib/etcd
```

**Paso 4:** Reinicia API Server y etcd

```bash
sudo mv /tmp/etcd.yaml /etc/kubernetes/manifests/
sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

# Espera a que vuelvan a iniciar
sleep 60
```

**Paso 5:** Verifica la restauración

```bash
# Desde tu máquina local (no el nodo master)
kubectl get namespace backup-test
# Debería existir nuevamente

kubectl get all -n backup-test
# Deberías ver el deployment con 3 réplicas

kubectl get namespace temporal
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
```

**Busca el evento:** `Successfully assigned default/scheduler-test to <nodo>`

**Pregunta:** ¿A qué nodo asignó el pod?

---

### 📝 Ejercicio 3.2: Node Selector

**Paso 1:** Etiqueta un nodo

```bash
# Obtén el nombre de un worker node
NODE=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}')

# Agregar etiqueta
kubectl label node $NODE disktype=ssd
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

**Paso 3:** Verifica que se asignó al nodo correcto

```bash
kubectl get pod ssd-pod -o wide
```

**Pregunta:** ¿Se asignó al nodo que etiquetaste?

---

### 📝 Ejercicio 3.3: Pod con Recursos Grandes

**Paso 1:** Crea un pod que requiere muchos recursos

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
        cpu: "1000"  # 1000 cores - imposible!
        memory: "1000Gi"
EOF
```

**Paso 2:** Observa por qué no se puede programar

```bash
kubectl describe pod huge-pod | grep -A 5 "Events:"
```

**Pregunta:** ¿Qué mensaje de error ves? ¿Por qué el Scheduler no puede asignar el pod?

---

### 📝 Ejercicio 3.4: Manual Scheduling

**Paso 1:** Crea un pod SIN que el Scheduler lo asigne

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: manual-schedule
spec:
  nodeName: ""  # Sin nodo asignado
  schedulerName: manual-scheduler  # Scheduler que no existe
  containers:
  - name: nginx
    image: nginx
EOF
```

**Paso 2:** Verifica que está en estado Pending

```bash
kubectl get pod manual-schedule
# STATUS: Pending
```

**Paso 3:** Asigna manualmente el pod a un nodo

```bash
NODE=$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[0].metadata.name}')

kubectl patch pod manual-schedule -p "{\"spec\":{\"nodeName\":\"$NODE\"}}"
```

**Paso 4:** Verifica que ahora corre

```bash
kubectl get pod manual-schedule -o wide
```

**Pregunta:** ¿Por qué el pod no requiere al Scheduler para correr una vez que le asignas `nodeName`?

---

## Parte 4: Controller Manager (20 minutos)

### 📝 Ejercicio 4.1: Reconciliation Loop del ReplicaSet Controller

**Paso 1:** Crea un Deployment

```bash
kubectl create deployment test-reconcile --image=nginx --replicas=3
```

**Paso 2:** Verifica los pods

```bash
kubectl get pods -l app=test-reconcile
# Deberías ver 3 pods
```

**Paso 3:** Elimina un pod manualmente

```bash
POD=$(kubectl get pods -l app=test-reconcile -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD
```

**Paso 4:** Observa inmediatamente los pods

```bash
watch kubectl get pods -l app=test-reconcile
```

**Pregunta:** ¿Qué sucede? ¿Cuánto tiempo tarda en aparecer un nuevo pod?

<details>
<summary>💡 Explicación</summary>
El ReplicaSet Controller detecta que hay solo 2 pods (desired: 3, actual: 2) y crea uno nuevo inmediatamente. Esto es el "reconciliation loop" en acción.
</details>

---

### 📝 Ejercicio 4.2: Node Controller

**Paso 1:** Simula un nodo "not ready" (solo en entornos de prueba)

```bash
# Desde un nodo worker
sudo systemctl stop kubelet
```

**Paso 2:** Observa el status del nodo

```bash
# Desde tu máquina
watch kubectl get nodes
```

**Espera ~40 segundos**

**Pregunta:** ¿Cuánto tiempo tarda en cambiar a `NotReady`?

**Paso 3:** Observa qué pasa con los pods en ese nodo

```bash
kubectl get pods -A -o wide --field-selector spec.nodeName=<nombre-del-nodo>
```

**Espera ~5 minutos**

**Pregunta:** ¿Los pods se mueven a otros nodos? ¿Cuánto tiempo tarda?

**Paso 4:** Restaura el nodo

```bash
# Desde el nodo worker
sudo systemctl start kubelet
```

---

### 📝 Ejercicio 4.3: Endpoint Controller

**Paso 1:** Crea un Service sin pods

```bash
kubectl create service clusterip test-endpoints --tcp=80:80
```

**Paso 2:** Verifica los endpoints (deberían estar vacíos)

```bash
kubectl get endpoints test-endpoints
# NAME              ENDPOINTS   AGE
# test-endpoints    <none>      10s
```

**Paso 3:** Crea pods que coincidan con el selector del Service

```bash
# El Service busca app=test-endpoints por defecto
kubectl run pod1 --image=nginx --labels=app=test-endpoints
kubectl run pod2 --image=nginx --labels=app=test-endpoints
kubectl run pod3 --image=nginx --labels=app=test-endpoints
```

**Paso 4:** Verifica los endpoints nuevamente

```bash
kubectl get endpoints test-endpoints -o yaml
```

**Pregunta:** ¿Cuántas IPs ves en los endpoints? ¿Coinciden con las IPs de los pods?

```bash
kubectl get pods -l app=test-endpoints -o wide
```

---

## Parte 5: Troubleshooting del Control Plane (10 minutos)

### 📝 Ejercicio 5.1: Logs de Componentes

**Paso 1:** Ver logs del API Server

```bash
kubectl logs -n kube-system kube-apiserver-<master-node> --tail=50
```

**Paso 2:** Ver logs del Scheduler

```bash
kubectl logs -n kube-system kube-scheduler-<master-node> --tail=50
```

**Paso 3:** Ver logs del Controller Manager

```bash
kubectl logs -n kube-system kube-controller-manager-<master-node> --tail=50
```

**Tarea:** Busca en los logs algún mensaje de WARNING o ERROR. ¿Qué dicen?

---

### 📝 Ejercicio 5.2: Health Checks

**Paso 1:** Verifica el health del API Server

```bash
curl -k $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')/healthz
# Debería retornar: ok
```

**Paso 2:** Verifica el health de etcd

```bash
# Desde el nodo master
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
```

---

## Verificación Final

### ✅ Checklist de Conocimientos

- [ ] Puedo hacer peticiones REST al API Server sin kubectl
- [ ] Entiendo el formato de la API de Kubernetes
- [ ] Sé cómo tomar un snapshot de etcd
- [ ] Puedo restaurar un cluster desde un backup
- [ ] Entiendo cómo el Scheduler asigna pods a nodos
- [ ] Puedo forzar un pod a un nodo específico
- [ ] Entiendo el reconciliation loop de los Controllers
- [ ] Sé cómo verificar el health de componentes del Control Plane
- [ ] Puedo troubleshootear problemas del Control Plane con logs

---

## Limpieza

```bash
# Eliminar recursos de prueba
kubectl delete pod api-test created-via-api scheduler-test ssd-pod huge-pod manual-schedule --ignore-not-found
kubectl delete deployment test-reconcile --ignore-not-found
kubectl delete service test-endpoints --ignore-not-found
kubectl delete pod pod1 pod2 pod3 --ignore-not-found
kubectl delete namespace backup-test temporal --ignore-not-found

# Eliminar archivos temporales
rm -f pod-via-api.json

# Si hiciste el restore, puedes limpiar
sudo rm -f /tmp/etcd-backup.db
sudo rm -rf /var/lib/etcd.backup  # Cuidado con este comando
```

---

## Próximo Laboratorio

➡️ **Laboratorio 03**: Worker Nodes - kubelet, kube-proxy y Container Runtime en profundidad

---

**¿Completaste el laboratorio?** ✅
