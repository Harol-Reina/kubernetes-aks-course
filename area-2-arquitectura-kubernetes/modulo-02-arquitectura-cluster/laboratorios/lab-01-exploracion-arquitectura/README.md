# Laboratorio 01: Exploración de la Arquitectura del Cluster

## Objetivos

Al finalizar este laboratorio, serás capaz de:
- ✓ Identificar todos los componentes del Control Plane en Minikube
- ✓ Inspeccionar el nodo Minikube y sus componentes
- ✓ Verificar la comunicación entre componentes
- ✓ Entender el flujo de creación de un recurso

## Duracion Estimada

60-90 minutos | Basico

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| Inspeccion del Control Plane | Identificar y describir pods del kube-system (etcd, apiserver, scheduler, controller-manager) |
| Comandos kubectl de exploracion | `kubectl get`, `kubectl describe`, `kubectl get events`, `kubectl logs` |
| Observacion de etcd | Inspeccion de configuracion y directorio de datos del pod etcd-minikube |
| Analisis de kube-system | Listado y clasificacion de todos los pods del namespace kube-system |
| Watch de eventos en tiempo real | `kubectl get events -w` para rastrear la creacion de recursos |
| API Watch | Simular el mecanismo watch que usan kubelet y controllers |

## Archivos del Laboratorio

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Script de limpieza de recursos creados durante el laboratorio |

> Este laboratorio usa exclusivamente comandos imperativos. No hay archivos YAML que aplicar.

## Pre-requisitos

- **Minikube instalado** con driver Docker
- **VM Ubuntu en Azure** funcionando
- `kubectl` configurado y funcionando
- Conexión SSH a la VM de Azure

## ⚠️ Nota sobre el Entorno

Este laboratorio está diseñado específicamente para **Minikube con driver Docker**. 
- Minikube crea un cluster **single-node** donde todos los componentes corren en un solo nodo
- El nodo se llama `minikube` (no `master-1` o `worker-1`)
- Todos los componentes del Control Plane corren como **pods** en el namespace `kube-system`

---

## Parte 1: Inspección del Control Plane en Minikube (25 minutos)

### 📝 Ejercicio 1.1: Identificar Componentes del Sistema

**Paso 1:** Verifica que Minikube esté corriendo

```bash
# Verificar status de Minikube
minikube status

# Deberías ver:
# minikube
# type: Control Plane
# host: Running
# kubelet: Running
# apiserver: Running
```

**Paso 2:** Lista todos los pods del sistema

```bash
kubectl get pods -n kube-system
```

**Pregunta:** ¿Cuántos pods del `kube-apiserver` existen? 

<details>
<summary>💡 Pista</summary>
En Minikube verás exactamente 1 pod de cada componente del Control Plane:
- kube-apiserver-minikube
- etcd-minikube
- kube-scheduler-minikube
- kube-controller-manager-minikube

Esto es normal en Minikube. En producción con HA verías 3+ de cada uno.
</details>

**Paso 3:** Identifica los componentes principales

```bash
kubectl get pods -n kube-system -o wide | grep -E 'etcd|kube-apiserver|kube-scheduler|kube-controller'
```

**Tarea:** Completa la siguiente tabla:

| Componente | Número de Instancias | Nodo |
|------------|---------------------|---------|
| etcd-minikube | 1 | minikube |
| kube-apiserver-minikube | 1 | minikube |
| kube-scheduler-minikube | 1 | minikube |
| kube-controller-manager-minikube | 1 | minikube |

---

### 📝 Ejercicio 1.2: Inspeccionar el API Server

**Paso 1:** Obtén los detalles del pod del API Server

```bash
# En Minikube el nombre es predecible
kubectl describe pod kube-apiserver-minikube -n kube-system
```

**Preguntas:**
1. ¿Qué imagen se está usando?
2. ¿Cuáles son los argumentos principales del comando?
3. ¿Qué puerto escucha el API Server? (buscar `--secure-port`)

**Paso 2:** Verifica los endpoints del API Server

```bash
kubectl get endpoints kubernetes -o yaml
```

**Pregunta:** ¿Qué IP(s) aparecen en los endpoints? ¿Coinciden con los nodos master?

---

### 📝 Ejercicio 1.3: Verificar etcd

**Paso 1:** Identifica el pod de etcd

```bash
kubectl get pods -n kube-system -l component=etcd
```

**Paso 2:** Inspecciona la configuración de etcd

```bash
ETCD_POD=$(kubectl get pods -n kube-system -l component=etcd -o name | head -1)
kubectl describe -n kube-system $ETCD_POD | grep -A 10 "Command:"
```

**Preguntas:**
1. ¿Qué puerto usa etcd para clientes? (buscar `--listen-client-urls`)
2. ¿Está configurado para clustering? (buscar `--initial-cluster`)
3. ¿Dónde está el directorio de datos? (buscar `--data-dir`)

**Paso 3:** (Opcional - solo si tienes acceso al nodo) Verifica el tamaño de la base de datos

```bash
# Desde dentro del nodo master
sudo du -sh /var/lib/etcd
```

---

### 📝 Ejercicio 1.4: Verificar Scheduler y Controller Manager

**Paso 1:** Verifica quién es el líder del Scheduler

```bash
kubectl get endpoints kube-scheduler -n kube-system -o yaml
```

**Busca en la sección `annotations` → `control-plane.alpha.kubernetes.io/leader`**

**Preguntas:**
1. ¿Qué nodo es actualmente el líder del Scheduler?
2. ¿Cuánto dura el lease? (buscar `leaseDurationSeconds`)

**Paso 2:** Verifica el Controller Manager

```bash
kubectl get endpoints kube-controller-manager -n kube-system -o yaml
```

**Pregunta:** ¿Es el mismo nodo líder para Scheduler y Controller Manager, o son diferentes?

---

## Parte 2: Inspección de Worker Nodes (25 minutos)

### 📝 Ejercicio 2.1: Listar Nodos

**Paso 1:** Lista todos los nodos del cluster

```bash
kubectl get nodes -o wide
```

**Tarea:** Completa la información de tus nodos:

| Nombre | Rol | Versión | IP Interna | Container Runtime |
|--------|-----|---------|-----------|------------------|
| | | | | |
| | | | | |

**Paso 2:** Obtén información detallada de un worker node

```bash
# Reemplaza <node-name> con el nombre de un worker
kubectl describe node <node-name>
```

**Preguntas:**
1. ¿Cuánta CPU tiene el nodo? (buscar `Capacity → cpu`)
2. ¿Cuánta memoria tiene? (buscar `Capacity → memory`)
3. ¿Cuántos pods puede ejecutar? (buscar `Capacity → pods`)
4. ¿Cuántos pods están corriendo actualmente? (buscar `Non-terminated Pods`)

---

### 📝 Ejercicio 2.2: Inspeccionar kubelet

**Paso 1:** (Requiere acceso SSH al nodo) Verifica el status de kubelet

```bash
# Desde el nodo worker
sudo systemctl status kubelet
```

**Paso 2:** Ver logs de kubelet

```bash
# Desde el nodo worker
sudo journalctl -u kubelet -f
```

**Deja esto corriendo en una terminal**

**Paso 3:** Crea un pod y observa los logs de kubelet

En otra terminal:

```bash
kubectl run test-kubelet --image=nginx --restart=Never
```

**Pregunta:** ¿Qué eventos ves en los logs de kubelet al crear el pod?

**Limpieza:**
```bash
kubectl delete pod test-kubelet
```

---

### 📝 Ejercicio 2.3: Inspeccionar kube-proxy

**Paso 1:** Lista los pods de kube-proxy

```bash
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide
```

**Pregunta:** ¿Cuántos pods de kube-proxy existen? ¿Por qué?

<details>
<summary>💡 Pista</summary>
kube-proxy corre como DaemonSet, entonces hay uno por cada nodo.
</details>

**Paso 2:** Verifica el modo de kube-proxy

```bash
# Obtener nombre de un pod de kube-proxy
PROXY_POD=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy -o name | head -1)

# Ver logs para encontrar el modo
kubectl logs -n kube-system $PROXY_POD | grep "Using"
```

**Pregunta:** ¿Está usando iptables o IPVS?

**Paso 3:** (Requiere acceso SSH) Verifica reglas de iptables

```bash
# Desde un nodo
sudo iptables -t nat -L KUBE-SERVICES -n | head -20
```

---

### 📝 Ejercicio 2.4: Inspeccionar Container Runtime

**Paso 1:** Identifica el container runtime

```bash
kubectl get nodes -o wide
```

**Busca la columna `CONTAINER-RUNTIME`**

**Paso 2:** (Requiere acceso SSH) Lista contenedores con crictl

```bash
# Desde un nodo
sudo crictl ps
```

**Paso 3:** Lista imágenes

```bash
sudo crictl images
```

**Preguntas:**
1. ¿Cuántos contenedores están corriendo en el nodo?
2. ¿Qué imagen usa el "pause container"?
3. ¿Por qué hay pause containers?

---

## Parte 3: Comunicación entre Componentes (20 minutos)

### 📝 Ejercicio 3.1: Rastrear la Creación de un Deployment

**Paso 1:** Abre 3 terminales:

**Terminal 1:** Observa eventos
```bash
kubectl get events -w
```

**Terminal 2:** Observa pods
```bash
watch kubectl get pods
```

**Terminal 3:** Crea deployment
```bash
kubectl create deployment web --image=nginx --replicas=3
```

**Tarea:** Documenta la secuencia de eventos que observas:

```
1. ____________________________________
2. ____________________________________
3. ____________________________________
4. ____________________________________
```

**Preguntas:**
1. ¿Qué componente creó el ReplicaSet?
2. ¿Qué componente asignó los pods a los nodos?
3. ¿Qué componente inició los contenedores?

---

### 📝 Ejercicio 3.2: Verificar Comunicación API Server ↔ etcd

**Paso 1:** Consulta un recurso directamente desde etcd (si tienes acceso)

```bash
# Desde el nodo master (requiere certificados)
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/deployments/default/web
```

**Pregunta:** ¿Puedes ver la definición del Deployment en formato binario/protobuf?

**Paso 2:** Lista todas las keys en etcd

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get / --prefix --keys-only | grep -E 'deployments|pods|services' | head -10
```

---

### 📝 Ejercicio 3.3: Watch API

**Paso 1:** Simula el watch API que usa kubelet

```bash
# Obtener la IP del API Server
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# Watch de pods (esto es lo que kubelet hace)
kubectl get pods --watch &
WATCH_PID=$!
```

**Paso 2:** Crea y elimina un pod

```bash
kubectl run test-watch --image=nginx
sleep 5
kubectl delete pod test-watch
```

**Observa cómo el watch recibe eventos en tiempo real**

**Limpieza:**
```bash
kill $WATCH_PID
```

---

## Parte 4: Desafíos Avanzados (20 minutos)

### 🚀 Desafío 1: Mapa Completo del Cluster

**Tarea:** Crea un diagrama que muestre:
- Todos los nodos (master y workers)
- Componentes del Control Plane en cada master
- Componentes de Worker en cada worker
- Direcciones IP de cada componente
- Puertos principales

**Herramientas sugeridas:** Draw.io, Mermaid, o papel y lápiz

---

### 🚀 Desafío 2: Simular Fallo de Componente

**Escenario:** Imagina que el API Server en un nodo master falla.

**Preguntas:**
1. ¿Seguirá funcionando el cluster?
2. ¿Qué componentes se verían afectados?
3. ¿Los pods en workers seguirán corriendo?
4. ¿Podrás crear nuevos pods?

**Prueba (solo en entorno de desarrollo):**

```bash
# En un cluster multi-master, detener API Server
sudo systemctl stop kubelet  # En un nodo master

# Verificar desde otro nodo
kubectl get nodes
kubectl get pods
```

---

### 🚀 Desafío 3: Análisis de Performance

**Tarea:** Mide la latencia de las siguientes operaciones:

```bash
# 1. Listar pods
time kubectl get pods

# 2. Crear un pod
time kubectl run test-perf --image=nginx --restart=Never
time kubectl wait --for=condition=Ready pod/test-perf --timeout=60s

# 3. Eliminar pod
time kubectl delete pod test-perf --grace-period=0 --force
```

**Registra los tiempos:**
- `kubectl get pods`: ______ segundos
- `kubectl run`: ______ segundos
- Pod ready: ______ segundos
- `kubectl delete`: ______ segundos

---

## Verificación Final

### ✅ Checklist de Conocimientos

Marca las afirmaciones que puedes explicar:

- [ ] Puedo nombrar los 4 componentes principales del Control Plane
- [ ] Entiendo la diferencia entre Control Plane y Data Plane
- [ ] Sé qué componentes usan leader election y cuáles no
- [ ] Puedo explicar el rol de kubelet en un Worker Node
- [ ] Entiendo cómo kube-proxy implementa Services
- [ ] Sé qué container runtime usa mi cluster
- [ ] Puedo rastrear el flujo completo desde `kubectl create` hasta contenedor corriendo
- [ ] Entiendo qué datos se almacenan en etcd
- [ ] Puedo identificar si mi cluster es single-master o HA
- [ ] Sé cómo verificar el health de cada componente

---

## Limpieza

```bash
# Eliminar recursos creados durante el laboratorio
kubectl delete deployment web --ignore-not-found
kubectl delete pod test-kubelet test-watch test-perf --ignore-not-found
```

---

## Recursos Adicionales

- 📖 [Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/)
- 📖 [etcd Documentation](https://etcd.io/docs/)
- 🎥 [Kubernetes Architecture Explained (video)](https://www.youtube.com/watch?v=8C_SCDbUJTg)

---

## Próximo Laboratorio

➡️ **Laboratorio 02**: Control Plane Práctico - Backup/Restore de etcd y análisis del API Server

---

**¿Completaste el laboratorio?** ✅

Si tuviste dificultades o encontraste algo interesante, documenta tus observaciones para discutir en clase.
