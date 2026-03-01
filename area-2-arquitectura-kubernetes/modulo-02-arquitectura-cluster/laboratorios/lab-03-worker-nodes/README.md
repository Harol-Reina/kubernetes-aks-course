# Laboratorio 03: Worker Nodes en Profundidad

## Objetivos

Al finalizar este laboratorio, seras capaz de:
- Configurar y troubleshootear kubelet
- Analizar reglas de iptables generadas por kube-proxy
- Interactuar con el Container Runtime usando crictl
- Debuggear problemas de networking en pods
- Optimizar recursos en Worker Nodes

## Duracion Estimada

90-120 minutos

## Pre-requisitos

- Cluster Kubernetes funcional
- Acceso SSH a Worker Nodes
- `crictl` instalado en los nodos
- Permisos de administrador

---

## Tecnicas y Conceptos Utilizados

| Tecnica / Concepto | Descripcion |
|---|---|
| Configuracion de kubelet | Inspeccion de /var/lib/kubelet/config.yaml para entender parametros como maxPods y containerRuntimeEndpoint |
| Liveness Probe con httpGet | Probe que falla intencionalmente para observar el ciclo de reinicio del contenedor por kubelet |
| Resource Management con cgroups | Verificacion de como requests y limits se traducen a valores de cgroups en el Worker Node |
| Eviction de pods por memoria | Simulacion de presion de memoria con stress para observar umbrales de eviction |
| Analisis de iptables de kube-proxy | Inspeccion de reglas NAT generadas por kube-proxy para ClusterIP y NodePort |
| IPVS mode de kube-proxy | Verificacion del modo de operacion de kube-proxy y diferencias con iptables |
| NodePort Routing | Trazado de reglas de iptables para trafico entrante por NodePort |
| Service sin selector y Endpoints manuales | Patron para conectar Services a recursos externos fuera del cluster |
| Inspeccion de contenedores con crictl | Uso de crictl ps, pods, inspect, logs y exec para gestionar contenedores |
| Pause container (sandbox) | Comprension del contenedor de red compartido en cada pod |
| Pod multi-contenedor | Verificacion de como crictl muestra los contenedores de un pod incluyendo el pause |
| Conectividad Pod-to-Pod | Prueba de comunicacion directa entre pods en distintos nodos |
| DNS Resolution con CoreDNS | Verificacion de resolucion de nombres de Services desde dentro de pods |
| NetworkPolicy deny-all | Bloqueo de todo el trafico Ingress hacia un pod con una politica sin reglas |
| NetworkPolicy allow especifico | Apertura selectiva de trafico desde pods con etiqueta especifica |
| QoS Classes (Guaranteed/Burstable/BestEffort) | Comprension de como Kubernetes clasifica pods segun sus requests y limits |

## Archivos YAML del Laboratorio

| Archivo | Ejercicio | Descripcion |
|---|---|---|
| `unhealthy-pod.yaml` | 1.2 | Pod con liveness probe hacia /nonexistent para observar reinicios del kubelet |
| `high-cpu-pod.yaml` | 1.3 | Pod con stress consumiendo 2 CPU para verificar cgroups y kubectl top |
| `memory-hog-pod.yaml` | 1.4 | Pod con stress consumiendo 1G de memoria para simular presion y eviction |
| `external-db-service.yaml` | 2.4 | Service sin selector mas Endpoints manual apuntando a IP externa 192.168.1.100 |
| `multi-container-pod.yaml` | 3.2 | Pod con nginx y sidecar busybox para explorar anatomia de pods con crictl |
| `netpol-deny-all.yaml` | 4.3 | NetworkPolicy que bloquea todo Ingress a pods con etiqueta app=backend |
| `netpol-allow-frontend.yaml` | 4.3 | NetworkPolicy que permite Ingress desde app=frontend a app=backend en puerto 80 |
| `guaranteed-pod.yaml` | 5.2 | Pod con requests == limits para demostrar la clase QoS Guaranteed |

---

## Parte 1: kubelet en Detalle (35 minutos)

### Ejercicio 1.1: Configuracion de kubelet

**Paso 1:** Verificar la configuracion de kubelet (desde un Worker Node)

```bash
# SSH al worker node
ssh worker-node-1

# Ver configuracion activa
sudo cat /var/lib/kubelet/config.yaml
```

**Preguntas:**
1. Que puerto usa kubelet? (buscar `port:`)
2. Cual es el maximo de pods permitidos? (buscar `maxPods:`)
3. Que container runtime endpoint usa? (buscar `containerRuntimeEndpoint:`)

---

### Ejercicio 1.2: Health Probes en Accion

**Paso 1:** Crear un pod con liveness probe que falla

```bash
kubectl apply -f unhealthy-pod.yaml
```

**Paso 2:** Observar los eventos del pod

```bash
watch kubectl get pod unhealthy-pod
```

**Paso 3:** En otra terminal, observar los eventos

```bash
kubectl get events --watch --field-selector involvedObject.name=unhealthy-pod
```

**Preguntas:**
1. Cuanto tiempo tarda en reiniciarse? (espera 2 fallos x 5 segundos)
2. Que mensaje de evento ves cuando kubelet mata el contenedor?
3. Cuantas veces se reinicia antes de entrar en CrashLoopBackOff?

**Paso 4:** Ver logs de kubelet (desde el worker node donde corre el pod)

```bash
# Desde el worker node
sudo journalctl -u kubelet | grep unhealthy-pod | tail -20
```

---

### Ejercicio 1.3: Resource Management

**Paso 1:** Crear pods con diferentes resource requests

```bash
kubectl apply -f high-cpu-pod.yaml
```

**Paso 2:** Verificar el consumo real de CPU

```bash
kubectl top pod high-cpu-pod
```

**Paso 3:** Desde el worker node, verificar cgroups

```bash
# SSH al nodo donde corre el pod
POD_ID=$(sudo crictl pods --name high-cpu-pod -q)

# Ver limites de CPU configurados
sudo cat /sys/fs/cgroup/cpu/kubepods.slice/kubepods-burstable.slice/kubepods-burstable-pod${POD_ID}.slice/cpu.shares
sudo cat /sys/fs/cgroup/cpu/kubepods.slice/kubepods-burstable.slice/kubepods-burstable-pod${POD_ID}.slice/cpu.cfs_quota_us
```

**Pregunta:** Como se traducen los requests y limits a valores de cgroups?

---

### Ejercicio 1.4: Eviction de Pods

**Paso 1:** Verificar los thresholds de eviction

```bash
# Desde el worker node
sudo cat /var/lib/kubelet/config.yaml | grep -A 10 eviction
```

**Paso 2:** Simular presion de memoria (solo en entorno de prueba)

```bash
kubectl apply -f memory-hog-pod.yaml
```

**Paso 3:** Observar el comportamiento

```bash
kubectl describe node <worker-node> | grep -A 5 "Allocated resources"
```

**Pregunta:** Que sucede cuando la memoria del nodo se agota?

---

## Parte 2: kube-proxy y Networking (30 minutos)

### Ejercicio 2.1: Analizar Reglas de iptables

**Paso 1:** Crear un Service simple

```bash
kubectl create deployment web --image=nginx --replicas=2
kubectl expose deployment web --port=80 --target-port=80
```

**Paso 2:** Obtener la ClusterIP del Service

```bash
SERVICE_IP=$(kubectl get svc web -o jsonpath='{.spec.clusterIP}')
echo "Service IP: $SERVICE_IP"
```

**Paso 3:** Desde un worker node, buscar la regla de iptables

```bash
# SSH al worker node
sudo iptables -t nat -L KUBE-SERVICES -n | grep $SERVICE_IP
```

**Deberias ver algo como:**
```
KUBE-SVC-XXXXX  tcp  --  0.0.0.0/0  10.96.100.50  tcp dpt:80
```

**Paso 4:** Explorar la cadena del Service

```bash
# Copia el nombre de la cadena (KUBE-SVC-XXXXX) y explorala
sudo iptables -t nat -L KUBE-SVC-XXXXX -n
```

**Pregunta:** Cuantas reglas ves? Como distribuye el trafico entre los pods?

<details>
<summary>Pista</summary>
Deberias ver reglas con `--probability` para balanceo estadistico entre endpoints.
</details>

---

### Ejercicio 2.2: IPVS Mode (si esta disponible)

**Paso 1:** Verificar el modo de kube-proxy

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
# Cuenta cuantas reglas hay
sudo iptables -t nat -L | wc -l
```

**Pregunta:** Cuantas reglas de iptables existen? Como escala esto con el numero de Services?

---

### Ejercicio 2.3: NodePort Routing

**Paso 1:** Crear un Service tipo NodePort

```bash
kubectl expose deployment web --type=NodePort --name=web-nodeport --port=80
```

**Paso 2:** Obtener el NodePort asignado

```bash
NODE_PORT=$(kubectl get svc web-nodeport -o jsonpath='{.spec.ports[0].nodePort}')
echo "NodePort: $NODE_PORT"
```

**Paso 3:** Buscar la regla de iptables para NodePort

```bash
# Desde el worker node
sudo iptables -t nat -L KUBE-NODEPORTS -n | grep $NODE_PORT
```

**Paso 4:** Probar el acceso desde fuera del cluster

```bash
# Desde tu maquina (no el nodo)
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
curl http://$NODE_IP:$NODE_PORT
```

**Pregunta:** Por que puedes acceder al Service desde cualquier nodo, incluso si los pods no estan en ese nodo?

---

### Ejercicio 2.4: Service sin Endpoints

**Paso 1:** Crear un Service manualmente (sin selector) apuntando a una IP externa

```bash
kubectl apply -f external-db-service.yaml
```

**Paso 2:** Verificar el Service

```bash
kubectl get svc external-db
kubectl get endpoints external-db
```

**Paso 3:** Probar la conexion desde un pod

```bash
kubectl run mysql-client --rm -it --image=mysql:8 -- mysql -h external-db -P 3306
```

**Pregunta:** Como puede un Service apuntar a recursos fuera del cluster?

---

## Parte 3: Container Runtime con crictl (30 minutos)

### Ejercicio 3.1: Inspeccion de Contenedores

**Paso 1:** Listar todos los contenedores (desde worker node)

```bash
sudo crictl ps
```

**Paso 2:** Listar TODOS los contenedores (incluyendo pausados)

```bash
sudo crictl ps -a
```

**Pregunta:** Cuantos contenedores "pause" ves? Por que existen?

---

### Ejercicio 3.2: Anatomia de un Pod

**Paso 1:** Crear un pod con multiples contenedores

```bash
kubectl apply -f multi-container-pod.yaml
```

**Paso 2:** Desde el worker node, listar los pods

```bash
sudo crictl pods --name multi-container
```

**Anota el POD ID**

**Paso 3:** Listar contenedores en ese pod

```bash
POD_ID=<pod-id-del-paso-anterior>
sudo crictl ps --pod $POD_ID
```

**Pregunta:** Cuantos contenedores ves? Deberia haber 2 o 3?

<details>
<summary>Respuesta</summary>
Deberias ver 3: nginx, sidecar, y el pause container (sandbox).
</details>

---

### Ejercicio 3.3: Inspeccionar Contenedor

**Paso 1:** Obtener el ID de un contenedor

```bash
CONTAINER_ID=$(sudo crictl ps --name nginx -q | head -1)
echo $CONTAINER_ID
```

**Paso 2:** Inspeccionar el contenedor

```bash
sudo crictl inspect $CONTAINER_ID | jq '.info.runtimeSpec.linux.namespaces'
```

**Pregunta:** Que namespaces esta usando el contenedor?

**Paso 3:** Ver configuracion de red

```bash
sudo crictl inspect $CONTAINER_ID | jq '.info.runtimeSpec.linux.resources'
```

---

### Ejercicio 3.4: Logs y Exec

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

**Pregunta:** Que IP tiene el contenedor? Es la misma que el pod?

```bash
kubectl get pod multi-container -o jsonpath='{.status.podIP}'
```

---

### Ejercicio 3.5: Imagenes

**Paso 1:** Listar imagenes en el nodo

```bash
sudo crictl images
```

**Paso 2:** Pull de una imagen manualmente

```bash
sudo crictl pull redis:latest
```

**Paso 3:** Verificar la imagen

```bash
sudo crictl images | grep redis
```

**Paso 4:** Eliminar la imagen

```bash
IMAGE_ID=$(sudo crictl images -q redis:latest)
sudo crictl rmi $IMAGE_ID
```

---

## Parte 4: Debugging de Networking (25 minutos)

### Ejercicio 4.1: Conectividad Pod-to-Pod

**Paso 1:** Crear dos pods en diferentes nodos

```bash
# Pod 1
kubectl run pod-a --image=nginx --overrides='{"spec":{"nodeSelector":{"kubernetes.io/hostname":"worker-1"}}}'

# Pod 2 en otro nodo
kubectl run pod-b --image=nginx --overrides='{"spec":{"nodeSelector":{"kubernetes.io/hostname":"worker-2"}}}'
```

**Paso 2:** Obtener las IPs

```bash
POD_A_IP=$(kubectl get pod pod-a -o jsonpath='{.status.podIP}')
POD_B_IP=$(kubectl get pod pod-b -o jsonpath='{.status.podIP}')

echo "Pod A: $POD_A_IP"
echo "Pod B: $POD_B_IP"
```

**Paso 3:** Probar conectividad

```bash
kubectl exec pod-a -- ping -c 3 $POD_B_IP
```

**Pregunta:** Los pods pueden comunicarse directamente? Atraviesan el Service?

---

### Ejercicio 4.2: DNS Resolution

**Paso 1:** Verificar DNS desde un pod

```bash
kubectl run dns-test --rm -it --image=busybox -- sh

# Dentro del pod:
nslookup kubernetes
nslookup web.default.svc.cluster.local
cat /etc/resolv.conf
```

**Pregunta:** Que nameserver esta configurado? Es el ClusterIP de CoreDNS?

```bash
kubectl get svc -n kube-system kube-dns
```

---

### Ejercicio 4.3: Network Policies (si CNI lo soporta)

**Paso 1:** Crear un pod backend

```bash
kubectl run backend --image=nginx --labels=app=backend
```

**Paso 2:** Crear una NetworkPolicy que bloquea todo el trafico

```bash
kubectl apply -f netpol-deny-all.yaml
```

**Paso 3:** Probar conectividad desde otro pod

```bash
BACKEND_IP=$(kubectl get pod backend -o jsonpath='{.status.podIP}')
kubectl run test --rm -it --image=busybox -- wget -O- --timeout=5 http://$BACKEND_IP
```

**Deberia FALLAR (timeout)**

**Paso 4:** Permitir trafico desde pods con label especifico

```bash
kubectl apply -f netpol-allow-frontend.yaml
```

**Paso 5:** Probar con un pod etiquetado

```bash
kubectl run frontend --rm -it --image=busybox --labels=app=frontend -- wget -O- --timeout=5 http://$BACKEND_IP
```

**Deberia FUNCIONAR**

---

### Ejercicio 4.4: Troubleshooting CNI

**Paso 1:** Verificar los pods del CNI plugin

```bash
kubectl get pods -n kube-system -l k8s-app=calico-node
# O el CNI que uses (flannel, cilium, etc.)
```

**Paso 2:** Ver logs del CNI

```bash
kubectl logs -n kube-system <cni-pod-name>
```

**Paso 3:** Desde un worker node, verificar interfaces de red

```bash
# SSH al worker node
ip link show
```

**Pregunta:** Que interfaces ves ademas de eth0? Para que sirven? (busca cali, veth, flannel, etc.)

---

## Parte 5: Performance Tuning (10 minutos)

### Ejercicio 5.1: kubelet Performance

**Paso 1:** Verificar las metricas de kubelet

```bash
# Desde el worker node
curl -k https://localhost:10250/metrics
```

**Paso 2:** Buscar metricas clave

```bash
curl -k https://localhost:10250/metrics | grep -E 'kubelet_running_pods|kubelet_runtime_operations_duration'
```

---

### Ejercicio 5.2: Optimizacion de Resources

**Paso 1:** Crear un pod SIN requests/limits

```bash
kubectl run no-limits --image=nginx
```

**Paso 2:** Observar en que QoS class esta

```bash
kubectl get pod no-limits -o jsonpath='{.status.qosClass}'
```

**Paso 3:** Crear un pod con requests = limits

```bash
kubectl apply -f guaranteed-pod.yaml
```

**Paso 4:** Verificar la QoS class

```bash
kubectl get pod guaranteed -o jsonpath='{.status.qosClass}'
```

**Pregunta:** Cual es la diferencia entre BestEffort, Burstable, y Guaranteed?

---

## Verificacion Final

### Checklist de Conocimientos

- [ ] Puedo configurar y troubleshootear kubelet
- [ ] Entiendo como funcionan las health probes
- [ ] Se como kubelet gestiona recursos con cgroups
- [ ] Puedo analizar reglas de iptables de kube-proxy
- [ ] Entiendo la diferencia entre ClusterIP y NodePort
- [ ] Puedo usar crictl para inspeccionar contenedores
- [ ] Entiendo el rol del pause container
- [ ] Puedo debuggear problemas de conectividad entre pods
- [ ] Se como verificar el funcionamiento del CNI plugin
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

## Proximo Laboratorio

> **Laboratorio 04**: Troubleshooting de Networking - Debugging avanzado de Services y DNS

---

**Completaste el laboratorio?**
