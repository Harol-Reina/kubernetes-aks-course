# Laboratorio 03: Worker Nodes en Profundidad

## Objetivos

Al finalizar este laboratorio, serás capaz de:
- ✓ Configurar y troubleshootear kubelet
- ✓ Analizar reglas de iptables generadas por kube-proxy
- ✓ Interactuar con el Container Runtime usando crictl
- ✓ Debuggear problemas de networking en pods
- ✓ Optimizar recursos en Worker Nodes

## Duración Estimada

⏱️ 90-120 minutos

## Pre-requisitos

- Cluster Kubernetes funcional
- Acceso SSH a Worker Nodes
- `crictl` instalado en los nodos
- Permisos de administrador

---

## Parte 1: kubelet en Detalle (35 minutos)

### 📝 Ejercicio 1.1: Configuración de kubelet

**Paso 1:** Verifica la configuración de kubelet (desde un Worker Node)

```bash
# SSH al worker node
ssh worker-node-1

# Ver configuración activa
sudo cat /var/lib/kubelet/config.yaml
```

**Preguntas:**
1. ¿Qué puerto usa kubelet? (buscar `port:`)
2. ¿Cuál es el máximo de pods permitidos? (buscar `maxPods:`)
3. ¿Qué container runtime endpoint usa? (buscar `containerRuntimeEndpoint:`)

---

### 📝 Ejercicio 1.2: Health Probes en Acción

**Paso 1:** Crea un pod con liveness probe que falla

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: unhealthy-pod
spec:
  containers:
  - name: app
    image: nginx
    livenessProbe:
      httpGet:
        path: /nonexistent  # Esta ruta no existe
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 2
EOF
```

**Paso 2:** Observa los eventos del pod

```bash
watch kubectl get pod unhealthy-pod
```

**Paso 3:** En otra terminal, observa los eventos

```bash
kubectl get events --watch --field-selector involvedObject.name=unhealthy-pod
```

**Preguntas:**
1. ¿Cuánto tiempo tarda en reiniciarse? (espera 2 fallos × 5 segundos)
2. ¿Qué mensaje de evento ves cuando kubelet mata el contenedor?
3. ¿Cuántas veces se reinicia antes de entrar en CrashLoopBackOff?

**Paso 4:** Ver logs de kubelet (desde el worker node donde corre el pod)

```bash
# Desde el worker node
sudo journalctl -u kubelet | grep unhealthy-pod | tail -20
```

---

### 📝 Ejercicio 1.3: Resource Management

**Paso 1:** Crea pods con diferentes resource requests

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: high-cpu-pod
spec:
  containers:
  - name: stress
    image: polinux/stress
    command: ["stress"]
    args: ["--cpu", "2", "--timeout", "300s"]
    resources:
      requests:
        cpu: "1000m"
        memory: "512Mi"
      limits:
        cpu: "2000m"
        memory: "1Gi"
EOF
```

**Paso 2:** Verifica el consumo real de CPU

```bash
kubectl top pod high-cpu-pod
```

**Paso 3:** Desde el worker node, verifica cgroups

```bash
# SSH al nodo donde corre el pod
POD_ID=$(sudo crictl pods --name high-cpu-pod -q)

# Ver límites de CPU configurados
sudo cat /sys/fs/cgroup/cpu/kubepods.slice/kubepods-burstable.slice/kubepods-burstable-pod${POD_ID}.slice/cpu.shares
sudo cat /sys/fs/cgroup/cpu/kubepods.slice/kubepods-burstable.slice/kubepods-burstable-pod${POD_ID}.slice/cpu.cfs_quota_us
```

**Pregunta:** ¿Cómo se traducen los requests y limits a valores de cgroups?

---

### 📝 Ejercicio 1.4: Eviction de Pods

**Paso 1:** Verifica los thresholds de eviction

```bash
# Desde el worker node
sudo cat /var/lib/kubelet/config.yaml | grep -A 10 eviction
```

**Paso 2:** Simula presión de memoria (⚠️ solo en entorno de prueba)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: memory-hog
spec:
  containers:
  - name: stress
    image: polinux/stress
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "1G", "--timeout", "600s"]
    resources:
      requests:
        memory: "100Mi"
      limits:
        memory: "2Gi"
EOF
```

**Paso 3:** Observa el comportamiento

```bash
kubectl describe node <worker-node> | grep -A 5 "Allocated resources"
```

**Pregunta:** ¿Qué sucede cuando la memoria del nodo se agota?

---

## Parte 2: kube-proxy y Networking (30 minutos)

### 📝 Ejercicio 2.1: Analizar Reglas de iptables

**Paso 1:** Crea un Service simple

```bash
kubectl create deployment web --image=nginx --replicas=2
kubectl expose deployment web --port=80 --target-port=80
```

**Paso 2:** Obtén la ClusterIP del Service

```bash
SERVICE_IP=$(kubectl get svc web -o jsonpath='{.spec.clusterIP}')
echo "Service IP: $SERVICE_IP"
```

**Paso 3:** Desde un worker node, busca la regla de iptables

```bash
# SSH al worker node
sudo iptables -t nat -L KUBE-SERVICES -n | grep $SERVICE_IP
```

**Deberías ver algo como:**
```
KUBE-SVC-XXXXX  tcp  --  0.0.0.0/0  10.96.100.50  tcp dpt:80
```

**Paso 4:** Explora la cadena del Service

```bash
# Copia el nombre de la cadena (KUBE-SVC-XXXXX) y explórala
sudo iptables -t nat -L KUBE-SVC-XXXXX -n
```

**Pregunta:** ¿Cuántas reglas ves? ¿Cómo distribuye el tráfico entre los pods?

<details>
<summary>💡 Pista</summary>
Deberías ver reglas con `--probability` para balanceo estadístico entre endpoints.
</details>

---

### 📝 Ejercicio 2.2: IPVS Mode (si está disponible)

**Paso 1:** Verifica el modo de kube-proxy

```bash
kubectl logs -n kube-system -l k8s-app=kube-proxy | grep "Using"
```

**Si usa IPVS:**

```bash
# Desde el worker node
sudo ipvsadm -L -n
```

**Si usa iptables:**

```bash
# Cuenta cuántas reglas hay
sudo iptables -t nat -L | wc -l
```

**Pregunta:** ¿Cuántas reglas de iptables existen? ¿Cómo escala esto con el número de Services?

---

### 📝 Ejercicio 2.3: NodePort Routing

**Paso 1:** Crea un Service tipo NodePort

```bash
kubectl expose deployment web --type=NodePort --name=web-nodeport --port=80
```

**Paso 2:** Obtén el NodePort asignado

```bash
NODE_PORT=$(kubectl get svc web-nodeport -o jsonpath='{.spec.ports[0].nodePort}')
echo "NodePort: $NODE_PORT"
```

**Paso 3:** Busca la regla de iptables para NodePort

```bash
# Desde el worker node
sudo iptables -t nat -L KUBE-NODEPORTS -n | grep $NODE_PORT
```

**Paso 4:** Prueba el acceso desde fuera del cluster

```bash
# Desde tu máquina (no el nodo)
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
curl http://$NODE_IP:$NODE_PORT
```

**Pregunta:** ¿Por qué puedes acceder al Service desde cualquier nodo, incluso si los pods no están en ese nodo?

---

### 📝 Ejercicio 2.4: Service sin Endpoints

**Paso 1:** Crea un Service manualmente (sin selector)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  ports:
  - port: 3306
    targetPort: 3306
---
apiVersion: v1
kind: Endpoints
metadata:
  name: external-db
subsets:
- addresses:
  - ip: 192.168.1.100  # IP externa (fuera del cluster)
  ports:
  - port: 3306
EOF
```

**Paso 2:** Verifica el Service

```bash
kubectl get svc external-db
kubectl get endpoints external-db
```

**Paso 3:** Prueba la conexión desde un pod

```bash
kubectl run mysql-client --rm -it --image=mysql:8 -- mysql -h external-db -P 3306
```

**Pregunta:** ¿Cómo puede un Service apuntar a recursos fuera del cluster?

---

## Parte 3: Container Runtime con crictl (30 minutos)

### 📝 Ejercicio 3.1: Inspección de Contenedores

**Paso 1:** Lista todos los contenedores (desde worker node)

```bash
sudo crictl ps
```

**Paso 2:** Lista TODOS los contenedores (incluyendo pausados)

```bash
sudo crictl ps -a
```

**Pregunta:** ¿Cuántos contenedores "pause" ves? ¿Por qué existen?

---

### 📝 Ejercicio 3.2: Anatomía de un Pod

**Paso 1:** Crea un pod con múltiples contenedores

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: multi-container
spec:
  containers:
  - name: nginx
    image: nginx
  - name: sidecar
    image: busybox
    command: ["sh", "-c", "while true; do echo Hello; sleep 10; done"]
EOF
```

**Paso 2:** Desde el worker node, lista los pods

```bash
sudo crictl pods --name multi-container
```

**Anota el POD ID**

**Paso 3:** Lista contenedores en ese pod

```bash
POD_ID=<pod-id-del-paso-anterior>
sudo crictl ps --pod $POD_ID
```

**Pregunta:** ¿Cuántos contenedores ves? ¿Debería haber 2 o 3?

<details>
<summary>💡 Respuesta</summary>
Deberías ver 3: nginx, sidecar, y el pause container (sandbox).
</details>

---

### 📝 Ejercicio 3.3: Inspeccionar Contenedor

**Paso 1:** Obtén el ID de un contenedor

```bash
CONTAINER_ID=$(sudo crictl ps --name nginx -q | head -1)
echo $CONTAINER_ID
```

**Paso 2:** Inspecciona el contenedor

```bash
sudo crictl inspect $CONTAINER_ID | jq '.info.runtimeSpec.linux.namespaces'
```

**Pregunta:** ¿Qué namespaces está usando el contenedor?

**Paso 3:** Ver configuración de red

```bash
sudo crictl inspect $CONTAINER_ID | jq '.info.runtimeSpec.linux.resources'
```

---

### 📝 Ejercicio 3.4: Logs y Exec

**Paso 1:** Ver logs de un contenedor

```bash
sudo crictl logs $CONTAINER_ID
```

**Paso 2:** Ejecutar comando en contenedor

```bash
sudo crictl exec -it $CONTAINER_ID sh
# Dentro del contenedor:
whoami
hostname
ip addr
exit
```

**Pregunta:** ¿Qué IP tiene el contenedor? ¿Es la misma que el pod?

```bash
kubectl get pod multi-container -o jsonpath='{.status.podIP}'
```

---

### 📝 Ejercicio 3.5: Imágenes

**Paso 1:** Lista imágenes en el nodo

```bash
sudo crictl images
```

**Paso 2:** Pull de una imagen manualmente

```bash
sudo crictl pull redis:latest
```

**Paso 3:** Verifica la imagen

```bash
sudo crictl images | grep redis
```

**Paso 4:** Elimina la imagen

```bash
IMAGE_ID=$(sudo crictl images -q redis:latest)
sudo crictl rmi $IMAGE_ID
```

---

## Parte 4: Debugging de Networking (25 minutos)

### 📝 Ejercicio 4.1: Conectividad Pod-to-Pod

**Paso 1:** Crea dos pods en diferentes nodos

```bash
# Pod 1
kubectl run pod-a --image=nginx --overrides='{"spec":{"nodeSelector":{"kubernetes.io/hostname":"worker-1"}}}'

# Pod 2 en otro nodo
kubectl run pod-b --image=nginx --overrides='{"spec":{"nodeSelector":{"kubernetes.io/hostname":"worker-2"}}}'
```

**Paso 2:** Obtén las IPs

```bash
POD_A_IP=$(kubectl get pod pod-a -o jsonpath='{.status.podIP}')
POD_B_IP=$(kubectl get pod pod-b -o jsonpath='{.status.podIP}')

echo "Pod A: $POD_A_IP"
echo "Pod B: $POD_B_IP"
```

**Paso 3:** Prueba conectividad

```bash
kubectl exec pod-a -- ping -c 3 $POD_B_IP
```

**Pregunta:** ¿Los pods pueden comunicarse directamente? ¿Atraviesan el Service?

---

### 📝 Ejercicio 4.2: DNS Resolution

**Paso 1:** Verifica DNS desde un pod

```bash
kubectl run dns-test --rm -it --image=busybox -- sh

# Dentro del pod:
nslookup kubernetes
nslookup web.default.svc.cluster.local
cat /etc/resolv.conf
```

**Pregunta:** ¿Qué nameserver está configurado? ¿Es el ClusterIP de CoreDNS?

```bash
kubectl get svc -n kube-system kube-dns
```

---

### 📝 Ejercicio 4.3: Network Policies (si CNI lo soporta)

**Paso 1:** Crea un pod backend

```bash
kubectl run backend --image=nginx --labels=app=backend
```

**Paso 2:** Crea una NetworkPolicy que bloquea todo el tráfico

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
EOF
```

**Paso 3:** Prueba conectividad desde otro pod

```bash
BACKEND_IP=$(kubectl get pod backend -o jsonpath='{.status.podIP}')
kubectl run test --rm -it --image=busybox -- wget -O- --timeout=5 http://$BACKEND_IP
```

**Debería FALLAR (timeout)**

**Paso 4:** Permite tráfico desde pods con label específico

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-frontend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
EOF
```

**Paso 5:** Prueba con un pod etiquetado

```bash
kubectl run frontend --rm -it --image=busybox --labels=app=frontend -- wget -O- --timeout=5 http://$BACKEND_IP
```

**Debería FUNCIONAR**

---

### 📝 Ejercicio 4.4: Troubleshooting CNI

**Paso 1:** Verifica los pods del CNI plugin

```bash
kubectl get pods -n kube-system -l k8s-app=calico-node
# O el CNI que uses (flannel, cilium, etc.)
```

**Paso 2:** Ver logs del CNI

```bash
kubectl logs -n kube-system <cni-pod-name>
```

**Paso 3:** Desde un worker node, verifica interfaces de red

```bash
# SSH al worker node
ip link show
```

**Pregunta:** ¿Qué interfaces ves además de eth0? ¿Para qué sirven? (busca cali, veth, flannel, etc.)

---

## Parte 5: Performance Tuning (10 minutos)

### 📝 Ejercicio 5.1: kubelet Performance

**Paso 1:** Verifica las métricas de kubelet

```bash
# Desde el worker node
curl -k https://localhost:10250/metrics
```

**Paso 2:** Busca métricas clave

```bash
curl -k https://localhost:10250/metrics | grep -E 'kubelet_running_pods|kubelet_runtime_operations_duration'
```

---

### 📝 Ejercicio 5.2: Optimización de Resources

**Paso 1:** Crea un pod SIN requests/limits

```bash
kubectl run no-limits --image=nginx
```

**Paso 2:** Observa en qué QoS class está

```bash
kubectl get pod no-limits -o jsonpath='{.status.qosClass}'
```

**Paso 3:** Crea un pod con requests = limits

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: guaranteed
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "500m"
        memory: "512Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
EOF
```

**Paso 4:** Verifica la QoS class

```bash
kubectl get pod guaranteed -o jsonpath='{.status.qosClass}'
```

**Pregunta:** ¿Cuál es la diferencia entre BestEffort, Burstable, y Guaranteed?

---

## Verificación Final

### ✅ Checklist de Conocimientos

- [ ] Puedo configurar y troubleshootear kubelet
- [ ] Entiendo cómo funcionan las health probes
- [ ] Sé cómo kubelet gestiona recursos con cgroups
- [ ] Puedo analizar reglas de iptables de kube-proxy
- [ ] Entiendo la diferencia entre ClusterIP y NodePort
- [ ] Puedo usar crictl para inspeccionar contenedores
- [ ] Entiendo el rol del pause container
- [ ] Puedo debuggear problemas de conectividad entre pods
- [ ] Sé cómo verificar el funcionamiento del CNI plugin
- [ ] Entiendo las QoS classes de Kubernetes

---

## Limpieza

```bash
kubectl delete pod unhealthy-pod high-cpu-pod memory-hog multi-container pod-a pod-b backend no-limits guaranteed dns-test frontend --ignore-not-found
kubectl delete deployment web --ignore-not-found
kubectl delete service web web-nodeport external-db --ignore-not-found
kubectl delete networkpolicy deny-all allow-from-frontend --ignore-not-found
kubectl delete endpoints external-db --ignore-not-found
```

---

## Próximo Laboratorio

➡️ **Laboratorio 04**: Troubleshooting de Networking - Debugging avanzado de Services y DNS

---

**¿Completaste el laboratorio?** ✅
