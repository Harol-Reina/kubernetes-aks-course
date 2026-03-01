# Capitulo 37: Troubleshooting Avanzado

Hemos diseñado el cluster con resiliencia en mente: HPA escala los Pods automaticamente, el Cluster Autoscaler añade nodos cuando hace falta, los PDB garantizan disponibilidad durante el mantenimiento. La arquitectura esta pensada para aguantar fallos. Pero los sistemas complejos fallan de formas complejas, y llega el momento en que las herramientas basicas no son suficientes.

Tienes un fallo intermitente que aparece solo bajo carga y solo en ciertos nodos. Un Pod en estado CrashLoopBackOff sin logs de error claros. Una degradacion de red entre namespaces que nadie puede reproducir en local. `kubectl describe pod` muestra "Running" pero la aplicacion no responde. `kubectl logs` devuelve el contenedor en bucle de reinicios pero los logs se truncan antes del error real. En estos escenarios, las tecnicas basicas de troubleshooting de los capitulos anteriores no llegan al fondo del problema.

El troubleshooting avanzado en Kubernetes usa un conjunto de herramientas de diagnostico de mas bajo nivel: contenedores efimeros (ephemeral containers) para inspeccionar Pods en ejecucion sin necesidad de reiniciarlos, `kubectl debug` para copiar Pods con herramientas adicionales de diagnostico de red, tcpdump para capturar trafico real dentro de un Pod, diagnostico a nivel de nodo con acceso directo al sistema operativo, y depuracion del plano de control cuando el problema esta en el API server, el scheduler o el etcd.

Piensa en la diferencia entre un botiquin de primeros auxilios y un laboratorio de diagnostico hospitalario completo. El troubleshooting basico del capitulo 28 es el botiquin: cura la mayoria de los problemas cotidianos. Este capitulo es el laboratorio diagnostico: resonancias magneticas, analisis de sangre, pruebas de estres — para los casos en que la causa raiz esta oculta.

En este capitulo aprenderas a usar contenedores efimeros para depuracion en vivo, a ejecutar tcpdump y netshoot dentro de Pods para analisis de red, a diagnosticar problemas a nivel de nodo con acceso al sistema operativo subyacente, a depurar el plano de control de Kubernetes en AKS, a perfilar rendimiento de aplicaciones en ejecucion, y a aplicar un framework metodologico de diagnostico para fallos en cascada.

---

## Framework Sistematico de Diagnostico

### El Modelo de 4 Capas

Cuando algo falla en Kubernetes, el error visible raramente es el error real. Un Pod en CrashLoopBackOff puede tener como causa raiz una NetworkPolicy que bloquea el acceso a la base de datos, un Secret montado incorrectamente, o un nodo con presion de memoria que mata procesos. El framework de 4 capas te da una estrategia sistematica para encontrar la causa raiz en lugar de tratar sintomas.

```
+----------------------------------------------------------+
|  Capa 4: APLICACION                                      |
|  ├── Logs del contenedor (stdout/stderr)                  |
|  ├── Health check failures (liveness/readiness probes)    |
|  └── Application errors (excepciones, timeouts, panics)   |
+----------------------------------------------------------+
         | (si la aplicacion parece OK, bajar)
+----------------------------------------------------------+
|  Capa 3: POD                                             |
|  ├── Estado: Pending, CrashLoopBackOff, ImagePullBackOff |
|  ├── Recursos: OOMKilled, CPU throttling                  |
|  └── Configuracion: ConfigMaps, Secrets, volumes          |
+----------------------------------------------------------+
         | (si el Pod parece OK, bajar)
+----------------------------------------------------------+
|  Capa 2: NODO                                            |
|  ├── Estado: NotReady, disk pressure, memory pressure     |
|  ├── kubelet logs (journalctl -u kubelet)                 |
|  └── Container runtime (containerd, CRI-O)               |
+----------------------------------------------------------+
         | (si el nodo parece OK, bajar)
+----------------------------------------------------------+
|  Capa 1: CLUSTER                                         |
|  ├── Control plane: API server, etcd, scheduler          |
|  ├── Networking: DNS, CNI plugin, kube-proxy             |
|  └── Storage: CSI drivers, PV/PVC binding               |
+----------------------------------------------------------+
```

**Regla fundamental**: empieza siempre por la Capa 4 (lo mas cercano al usuario) y baja solo cuando hayas descartado cada capa. El 80% de los problemas en produccion se resuelven en las capas 3 y 4.

### Los 5 Porques en Kubernetes

La tecnica de los "5 Porques" (originaria de Toyota) es especialmente eficaz en sistemas distribuidos, donde los sintomas y las causas estan separados por capas de abstraccion.

**Ejemplo real — La aplicacion no responde a los usuarios:**

```
Por que 1: ?Por que los usuarios ven errores 503?
  Respuesta: El Service no tiene Endpoints activos.

Por que 2: ?Por que no hay Endpoints activos?
  Respuesta: Los Pods estan en estado NotReady.

Por que 3: ?Por que los Pods estan NotReady?
  Respuesta: El readinessProbe falla con HTTP 500.

Por que 4: ?Por que la aplicacion devuelve HTTP 500?
  Respuesta: No puede conectar a la base de datos.

Por que 5: ?Por que no puede conectar a la base de datos?
  Respuesta: La NetworkPolicy del namespace de DB fue actualizada
             y ya no permite trafico desde el namespace de la app.

CAUSA RAIZ: cambio en NetworkPolicy. Solucion: actualizar la policy.
```

Sin este proceso, el operador podria haber perdido horas reiniciando Pods o aumentando recursos, sin tocar la causa real.

### Comandos de Primera Respuesta

Antes de profundizar en cualquier capa, ejecuta estos comandos para tener una imagen completa del estado del cluster:

```bash
# Vision general del cluster en 60 segundos
kubectl get nodes -o wide
# SALIDA ESPERADA:
# NAME           STATUS   ROLES           AGE   VERSION   INTERNAL-IP    OS-IMAGE
# node-1         Ready    control-plane   30d   v1.28.0   192.168.1.10   Ubuntu 22.04
# node-2         Ready    <none>          30d   v1.28.0   192.168.1.11   Ubuntu 22.04
# node-3         Ready    <none>          30d   v1.28.0   192.168.1.12   Ubuntu 22.04

# Pods con problemas en todos los namespaces
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
# SALIDA ESPERADA (si hay problemas):
# NAMESPACE    NAME               READY   STATUS             RESTARTS   AGE
# production   web-app-xyz123     0/1     CrashLoopBackOff   5          3m
# staging      db-migration-abc   0/1     Pending            0          10m

# Eventos recientes de todo el cluster (ordenados por tiempo)
kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -20

# Uso de recursos por nodo
kubectl top nodes
# SALIDA ESPERADA:
# NAME     CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# node-1   245m         12%    1823Mi          47%
# node-2   890m         44%    3102Mi          80%  <- nodo bajo presion
# node-3   120m         6%     956Mi           25%
```

---

## Estrategias de Diagnostico

### Flujo de Troubleshooting

```
1. Identificar el problema
   (que falla? cuando? en que condiciones?)
   |
2. Recopilar informacion
   (kubectl describe, logs, events, top)
   |
3. Analizar logs y metricas
   (correlacionar timestamps, buscar patrones)
   |
4. Probar hipotesis
   (cambio controlado, una variable a la vez)
   |
5. Implementar solucion
   (con rollback plan)
   |
6. Verificar resolucion
   (confirmar que el sintoma desaparecio)
   |
7. Documentar y prevenir
   (post-mortem, alarmas, runbooks)
```

---

## Comandos de Diagnostico

### Informacion del Cluster

```bash
# Estado general del cluster
kubectl cluster-info
kubectl get nodes
kubectl top nodes

# Eventos del cluster
kubectl get events --sort-by=.metadata.creationTimestamp

# Recursos del sistema
kubectl get pods -n kube-system
kubectl describe node <node-name>
```

### Diagnostico de Pods

```bash
# Estado de pods
kubectl get pods -o wide
kubectl describe pod <pod-name>

# Logs detallados
kubectl logs <pod-name> -c <container-name> --previous
kubectl logs <pod-name> --since=1h --tail=100

# Ejecutar comandos en pod
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec <pod-name> -- ps aux
kubectl exec <pod-name> -- netstat -tulpn
```

### Diagnostico de Red

```bash
# Conectividad entre pods
kubectl run test-pod --image=curlimages/curl -i --rm --restart=Never -- curl <service-url>

# DNS resolution
kubectl run test-dns --image=busybox -i --rm --restart=Never -- nslookup kubernetes.default

# Network policies
kubectl describe networkpolicy <policy-name>
```

---

## Pod Debugging en Profundidad

### Estado Pending: Por Que un Pod No Se Programa

Un Pod en estado Pending significa que el scheduler no ha podido asignarlo a ningun nodo. Hay cuatro causas principales.

#### Causa 1: Recursos Insuficientes

El Pod solicita mas CPU o memoria de la que ningun nodo puede ofrecer en este momento.

```bash
# Diagnostico
kubectl describe pod <nombre-pod>
# Buscar en la seccion Events:
# Warning  FailedScheduling  0/3 nodes are available:
#   1 Insufficient cpu, 2 Insufficient memory.

# Ver capacidad disponible por nodo
kubectl describe nodes | grep -A 8 "Allocated resources"
# SALIDA ESPERADA:
# Allocated resources:
#   (Total limits may be over 100 percent, i.e., overcommitted.)
#   Resource           Requests     Limits
#   --------           --------     ------
#   cpu                1750m (87%)  2200m (110%)
#   memory             2Gi (52%)    4Gi (100%)
#   ephemeral-storage  0 (0%)       0 (0%)

# Solucion: reducir las requests del Pod o añadir nodos al cluster
kubectl get pod <nombre-pod> -o yaml | grep -A 6 "resources:"
```

#### Causa 2: NodeSelector o Affinity Sin Match

El Pod tiene restricciones de donde puede ejecutarse que no coinciden con ningun nodo disponible.

```bash
# Diagnostico
kubectl describe pod <nombre-pod>
# Buscar en Events:
# Warning  FailedScheduling  0/3 nodes are available:
#   3 node(s) didn't match node selector.

# Ver labels de los nodos
kubectl get nodes --show-labels
# SALIDA ESPERADA:
# NAME     STATUS   LABELS
# node-1   Ready    kubernetes.io/hostname=node-1,disktype=ssd,...
# node-2   Ready    kubernetes.io/hostname=node-2,disktype=hdd,...

# Ver que nodeSelector tiene el Pod
kubectl get pod <nombre-pod> -o jsonpath='{.spec.nodeSelector}'
# SALIDA: {"disktype":"nvme"}  <- no existe en ningun nodo

# Solucion: añadir el label al nodo o corregir el nodeSelector
kubectl label node node-1 disktype=nvme
```

#### Causa 3: Taint Sin Toleration

Un nodo tiene un taint y el Pod no tiene la toleration correspondiente.

```bash
# Ver taints en los nodos
kubectl describe nodes | grep Taints
# SALIDA ESPERADA:
# Taints: node-role.kubernetes.io/control-plane:NoSchedule
# Taints: dedicated=gpu:NoSchedule

# Ver tolerations del Pod
kubectl get pod <nombre-pod> -o jsonpath='{.spec.tolerations}'

# En el descriptor del Pod, añadir toleration:
# tolerations:
# - key: "dedicated"
#   operator: "Equal"
#   value: "gpu"
#   effect: "NoSchedule"
```

#### Causa 4: PVC en Estado Pending

El Pod espera un PersistentVolumeClaim que aun no esta bound.

```bash
# Diagnostico
kubectl describe pod <nombre-pod>
# Events:
# Warning  FailedScheduling  0/3 nodes are available:
#   3 pod has unbound immediate PersistentVolumeClaims.

# Ver estado del PVC
kubectl get pvc
# SALIDA:
# NAME       STATUS    VOLUME   CAPACITY   STORAGECLASS   AGE
# data-pvc   Pending   <none>   <none>     fast-ssd       5m

# Diagnosticar el PVC (ver seccion Storage Debugging)
kubectl describe pvc data-pvc
```

---

### Estado CrashLoopBackOff: Diagnostico Profundo

CrashLoopBackOff significa que el contenedor se inicia, falla (sale con codigo != 0), y Kubernetes lo reinicia con espera exponencial: 10s, 20s, 40s, 80s, 160s... hasta un maximo de 5 minutos entre reinicios. Cuantos mas reinicios, mayor la espera.

```
Reinicio 1: espera  10 segundos
Reinicio 2: espera  20 segundos
Reinicio 3: espera  40 segundos
Reinicio 4: espera  80 segundos
Reinicio 5: espera 160 segundos
Reinicio 6+: espera 300 segundos (5 minutos, maximo)
```

#### Diagnostico con Exit Codes

El codigo de salida del contenedor es la clave mas importante:

```bash
# Ver codigo de salida del ultimo crash
kubectl describe pod <nombre-pod>
# Buscar la seccion "Last State":
#   Last State:     Terminated
#     Reason:       Error
#     Exit Code:    1         <- aqui esta la clave
#     Started:      Mon, 01 Mar 2026 10:00:00 +0000
#     Finished:     Mon, 01 Mar 2026 10:00:05 +0000

# Referencia de exit codes:
#   0   = salida limpia (no deberia reiniciarse con restartPolicy=Always)
#   1   = error generico de aplicacion
#   2   = uso incorrecto del comando shell
#   126 = permiso denegado (no ejecutable)
#   127 = comando no encontrado
#   128 = señal invalida
#   137 = OOMKilled (128 + SIGKILL=9)    <- memoria excedida
#   139 = Segmentation fault (128 + SIGSEGV=11)
#   143 = SIGTERM (terminacion ordenada, puede ser normal)
#   255 = salida por error de aplicacion (codigo fuera de rango)
```

#### Ver Logs del Contenedor Caido

```bash
# Logs del contenedor ANTES de que se cayera (contenedor anterior)
kubectl logs <nombre-pod> --previous
# Si el Pod tiene multiples contenedores:
kubectl logs <nombre-pod> -c <nombre-contenedor> --previous

# SALIDA ESPERADA (ejemplo error de configuracion):
# [ERROR] Failed to connect to database: connection refused
# [ERROR] Could not read config file: /config/app.conf: no such file or directory
# [FATAL] Initialization failed, exiting with code 1

# Logs con timestamps para correlacion
kubectl logs <nombre-pod> --previous --timestamps
# SALIDA:
# 2026-03-01T10:00:01Z [INFO]  Starting application...
# 2026-03-01T10:00:02Z [ERROR] Missing environment variable: DB_PASSWORD
# 2026-03-01T10:00:02Z [FATAL] Exiting
```

#### Causas Comunes de CrashLoopBackOff

**Error de aplicacion** (exit code 1): revisar logs para el mensaje de error. Puede ser un bug en el codigo o una condicion de startup no manejada.

**Comando o args incorrectos** (exit code 127):

```bash
# Verificar el comando configurado
kubectl get pod <nombre-pod> -o jsonpath='{.spec.containers[0].command}'
kubectl get pod <nombre-pod> -o jsonpath='{.spec.containers[0].args}'

# Probar la imagen manualmente con shell
kubectl run debug --rm -it --image=<imagen> -- /bin/sh
```

**Variable de entorno faltante**:

```bash
# Ver variables de entorno del contenedor
kubectl exec <nombre-pod> -- env
# O desde el descriptor:
kubectl get pod <nombre-pod> -o yaml | grep -A 20 "env:"

# Verificar que los Secrets y ConfigMaps referenciados existen
kubectl get configmap <nombre-cm>
kubectl get secret <nombre-secret>
```

**Problema de permisos** (exit code 126 o 1):

```bash
# El contenedor intenta escribir en un directorio de solo lectura
kubectl describe pod <nombre-pod>
# Events:
# Warning  Failed  Error: failed to create containerd task:
#   failed to create shim task: OCI runtime create failed:
#   container_linux.go:380: starting container process caused:
#   process_linux.go:545: container init caused:
#   rootfs_linux.go:76: mounting ... permission denied

# Solucion: usar securityContext con el usuario/grupo correcto
# o ajustar los permisos del volumen con initContainer
```

---

### ImagePullBackOff: Cuando la Imagen No Se Puede Descargar

```bash
# Diagnostico principal
kubectl describe pod <nombre-pod>
# Buscar en Events:
# Warning  Failed     Failed to pull image "myapp:v2.1":
#   rpc error: code = Unknown desc = failed to pull and unpack image:
#   ... : unauthorized: authentication required

# Mensajes comunes y sus causas:
#
# "repository does not exist or may require 'docker login'"
#   -> el nombre de la imagen es incorrecto o el registry es privado
#
# "unauthorized: authentication required"
#   -> registry privado sin imagePullSecret configurado
#
# "manifest unknown"
#   -> el tag especificado no existe en el registry
#
# "network timeout"
#   -> el nodo no tiene acceso de red al registry

# Verificar si la imagen existe (desde tu maquina local)
docker pull myapp:v2.1

# Ver que imagePullSecrets tiene el Pod
kubectl get pod <nombre-pod> -o jsonpath='{.spec.imagePullSecrets}'

# Crear imagePullSecret para un registry privado
kubectl create secret docker-registry regcred \
  --docker-server=registry.example.com \
  --docker-username=usuario \
  --docker-password=contraseña \
  --docker-email=email@example.com

# Verificar que el ServiceAccount del Pod tiene el Secret
kubectl get serviceaccount default -o yaml
```

---

### OOMKilled: El Contenedor Supero el Limite de Memoria

OOMKilled (Out Of Memory Killed) ocurre cuando el contenedor intenta usar mas memoria que su `resources.limits.memory`. El kernel de Linux mata el proceso con SIGKILL (señal 9), resultando en exit code 137.

```bash
# Diagnostico
kubectl describe pod <nombre-pod>
# Buscar en "Last State":
#   Last State:     Terminated
#     Reason:       OOMKilled       <- confirmacion
#     Exit Code:    137
#     Started:      Mon, 01 Mar 2026 09:55:00 +0000
#     Finished:     Mon, 01 Mar 2026 09:55:47 +0000

# Ver uso actual de memoria del Pod
kubectl top pod <nombre-pod>
# SALIDA:
# NAME             CPU(cores)   MEMORY(bytes)
# web-app-xyz123   45m          498Mi          <- cerca del limite

# Ver el limite configurado
kubectl get pod <nombre-pod> -o jsonpath='{.spec.containers[0].resources.limits.memory}'
# SALIDA: 512Mi

# Ver historial de reinicios y cuando ocurrieron
kubectl get pod <nombre-pod> -o jsonpath='{range .status.containerStatuses[*]}{.name}: restartCount={.restartCount}{"\n"}{end}'
```

**Dos soluciones posibles:**

1. Aumentar el limite de memoria si la aplicacion realmente lo necesita:

```yaml
resources:
  requests:
    memory: "256Mi"
  limits:
    memory: "1Gi"   # incremento justificado
```

2. Investigar y corregir el memory leak en la aplicacion (solucion correcta a largo plazo).

---

## Escenarios Comunes de Troubleshooting

### Pod en Estado Pending

```bash
# Verificar recursos del nodo
kubectl describe node

# Verificar PodDisruptionBudgets
kubectl get pdb -A

# Verificar taints y tolerations
kubectl describe node | grep Taints
```

### Pod en CrashLoopBackOff

```bash
# Ver logs del contenedor anterior
kubectl logs <pod-name> --previous

# Verificar health checks
kubectl describe pod <pod-name> | grep -A 10 "Liveness\|Readiness"

# Verificar recursos
kubectl top pod <pod-name>
```

### Problemas de Conectividad

```bash
# Verificar servicios
kubectl get svc
kubectl get endpoints

# Probar conectividad de red
kubectl exec -it <pod-name> -- telnet <service-ip> <port>

# Verificar DNS
kubectl exec -it <pod-name> -- cat /etc/resolv.conf
```

---

## Node Debugging

### Estado NotReady: Cuando un Nodo Deja de Funcionar

Un nodo en estado NotReady puede deberse a que el kubelet dejo de funcionar, que hay problemas de red entre el nodo y el control plane, o que los certificados del nodo expiraron.

```bash
# Identificar nodos con problema
kubectl get nodes
# SALIDA:
# NAME     STATUS     ROLES    AGE   VERSION
# node-1   Ready      <none>   30d   v1.28.0
# node-2   NotReady   <none>   30d   v1.28.0   <- problema aqui
# node-3   Ready      <none>   30d   v1.28.0

# Diagnostico detallado del nodo
kubectl describe node node-2
# Buscar la seccion "Conditions":
#   Type                 Status    Reason
#   ----                 ------    ------
#   MemoryPressure       False     KubeletHasSufficientMemory
#   DiskPressure         False     KubeletHasNoDiskPressure
#   PIDPressure          False     KubeletHasSufficientPID
#   Ready                False     KubeletNotReady   <- kubelet no responde
#
# Y en Events:
#   Node node-2 status is now: NodeNotReady

# En el nodo (via SSH):
systemctl status kubelet
# SALIDA SI ESTA CAIDO:
# kubelet.service - kubelet: The Kubernetes Node Agent
#   Loaded: loaded
#   Active: failed (Result: exit-code) since Mon 2026-03-01 10:00:00

# Ver logs del kubelet en tiempo real
journalctl -u kubelet -f --lines=100
# Buscar errores como:
# "certificate has expired or is not yet valid"
# "failed to run Kubelet: unable to determine runtime API version"
# "failed to create listener, error listen tcp: bind: address already in use"

# Reiniciar el kubelet
systemctl restart kubelet
systemctl status kubelet
```

---

### Disk Pressure: El Nodo Se Queda Sin Espacio

Cuando el uso de disco supera el umbral de eviction del kubelet (por defecto 85% de capacidad), el nodo entra en estado `DiskPressure=True` y comienza a desalojar Pods con QoS BestEffort primero.

```bash
# Ver condicion de DiskPressure
kubectl describe node <nombre-nodo>
# Conditions:
#   DiskPressure   True   KubeletHasDiskPressure   <- problema

# Ver uso de disco en el nodo (via SSH)
df -h
# SALIDA:
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sda1        50G   46G  4.0G  92% /           <- disco casi lleno
# overlay         50G   46G  4.0G  92% /var/lib/containerd

# Ver que usa mas espacio
du -sh /var/lib/containerd/*
# SALIDA:
# 2.1G  /var/lib/containerd/io.containerd.content.v1.content
# 15G   /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs
# 890M  /var/lib/containerd/io.containerd.metadata.v1.bolt

# Limpiar imagenes de contenedor no utilizadas
crictl rmi --prune
# SALIDA:
# Deleted: sha256:abc123...
# Deleted: sha256:def456...
# 3.2GB freed

# Limpiar Pods completados/fallidos
kubectl delete pods -A --field-selector=status.phase=Succeeded
kubectl delete pods -A --field-selector=status.phase=Failed

# Ver recursos asignados para detectar pods que consumen mucho disco efimero
kubectl describe node <nombre-nodo> | grep -A 10 "Allocated resources"
```

---

### Memory Pressure: El Nodo Bajo Presion de Memoria

Cuando la memoria disponible del nodo cae por debajo del umbral de eviction del kubelet (por defecto 100Mi disponibles), el nodo entra en `MemoryPressure=True` y el kernel de Linux puede matar procesos aleatoriamente mediante el OOM killer del nodo (diferente al OOMKilled de contenedor).

```bash
# Monitorear uso de memoria en tiempo real
kubectl top nodes
# SALIDA:
# NAME     CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# node-1   245m         12%    1823Mi          47%
# node-2   890m         44%    3840Mi          99%   <- critico
# node-3   120m         6%     956Mi           25%

# En el nodo (via SSH): ver uso real de memoria
free -h
# SALIDA:
#               total    used    free   shared  buff/cache  available
# Mem:           3.8Gi   3.7Gi   50Mi    120Mi       320Mi       80Mi

# Ver que procesos usan mas memoria
ps aux --sort=-%mem | head -15

# Los Pods se desalojan en este orden segun su QoS class:
#   1. BestEffort (sin requests ni limits)     <- primero en ser desalojado
#   2. Burstable (requests < limits)
#   3. Guaranteed (requests == limits)         <- ultimo en ser desalojado

# Ver la QoS class de un Pod
kubectl get pod <nombre-pod> -o jsonpath='{.status.qosClass}'
# SALIDA: Guaranteed / Burstable / BestEffort
```

---

## Network Debugging

### DNS Resolution: Cuando Los Nombres No Resuelven

El DNS de Kubernetes (CoreDNS) es critico: sin el, los Services no son accesibles por nombre, y la mayoria de aplicaciones dejan de funcionar.

```bash
# Test de DNS desde dentro de un Pod (metodo recomendado)
kubectl run dns-test --rm -it --image=busybox:1.28 --restart=Never -- \
  nslookup kubernetes.default

# SALIDA ESPERADA (DNS funcionando correctamente):
# Server:    10.96.0.10
# Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
#
# Name:      kubernetes.default
# Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local

# SALIDA SI EL DNS FALLA:
# Server:    10.96.0.10
# nslookup: can't resolve 'kubernetes.default'
# (o timeout sin respuesta)

# Test mas completo con dig
kubectl run dns-test --rm -it --image=infoblox/dnstools --restart=Never -- \
  dig kubernetes.default.svc.cluster.local

# Verificar estado de CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
# SALIDA ESPERADA:
# NAME                      READY   STATUS    RESTARTS   AGE
# coredns-565d847f94-abc12  1/1     Running   0          30d
# coredns-565d847f94-def34  1/1     Running   0          30d

# Ver logs de CoreDNS para errores
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50
# Buscar errores como:
# [ERROR] plugin/errors: 2 SERVFAIL (reason: upstream loop detected)
# [ERROR] plugin/errors: 2 NXDOMAIN (nombre no existe en DNS externo)
```

---

### Service Discovery: Cuando los Services No Son Alcanzables

```bash
# Paso 1: verificar que el Service existe y tiene la IP correcta
kubectl get svc <nombre-servicio>
# SALIDA:
# NAME         TYPE        CLUSTER-IP      PORT(S)   AGE
# web-service  ClusterIP   10.96.142.101   80/TCP    5d

# Paso 2: verificar que hay Endpoints (Pods seleccionados)
kubectl get endpoints <nombre-servicio>
# SALIDA SI FUNCIONA:
# NAME         ENDPOINTS                       AGE
# web-service  10.244.1.15:80,10.244.2.22:80   5d
#
# SALIDA SI HAY PROBLEMA (sin endpoints):
# NAME         ENDPOINTS   AGE
# web-service  <none>      5d
# <- el selector del Service no coincide con los labels de los Pods

# Diagnosticar selector mismatch
kubectl describe svc <nombre-servicio> | grep Selector
# SALIDA: Selector: app=web-frontend

kubectl get pods -l app=web-frontend
# Si no devuelve pods, el label en los Pods es diferente:
kubectl get pods --show-labels | grep web
# SALIDA: web-pod   Running   app=webfrontend   <- falta el guion

# Solucion: corregir el selector en el Service o el label en los Pods

# Paso 3: verificar conectividad directa al Service
kubectl run test --rm -it --image=curlimages/curl --restart=Never -- \
  curl -v http://web-service.default.svc.cluster.local:80
# SALIDA ESPERADA:
# * Connected to web-service.default.svc.cluster.local (10.96.142.101) port 80
# > GET / HTTP/1.1
# < HTTP/1.1 200 OK
```

---

### Conectividad Entre Namespaces

La comunicacion entre namespaces requiere usar el FQDN (Fully Qualified Domain Name):

```
<service>.<namespace>.svc.cluster.local
```

```bash
# Formato FQDN: service.namespace.svc.cluster.local
# Ejemplos:
# web-frontend.production.svc.cluster.local
# postgres.databases.svc.cluster.local
# redis-cache.caching.svc.cluster.local

# Test de conectividad entre namespaces
kubectl run test -n desarrollo --rm -it \
  --image=curlimages/curl --restart=Never -- \
  curl http://web-service.produccion.svc.cluster.local

# Si falla con timeout: posible NetworkPolicy bloqueando el trafico
kubectl get networkpolicy -A
kubectl describe networkpolicy <nombre> -n produccion
# Buscar reglas de ingress que restrinjan los namespaces permitidos

# Ver si el trafico esta bloqueado por una NetworkPolicy de deny-all
kubectl get networkpolicy -n produccion
# Si hay una policy de deny-all y el namespace de origen no esta en la lista
# de permitidos, el trafico sera bloqueado silenciosamente (sin error, solo timeout)
```

---

### Conectividad Externa Desde Pods

```bash
# Test de conectividad a Internet desde un Pod
kubectl run test --rm -it --image=curlimages/curl --restart=Never -- \
  curl -v https://httpbin.org/ip

# SALIDA ESPERADA:
# * Trying 18.232.199.152:443...
# * SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256
# < HTTP/2 200
# {
#   "origin": "203.0.113.45"   <- IP del nodo de salida
# }

# SALIDA SI FALLA (sin acceso externo):
# * Trying 18.232.199.152:443...
# * Connection timed out after 30000 milliseconds
# curl: (28) Connection timed out after 30000 milliseconds

# Si falla: verificar que los nodos tienen ruta a Internet
# En AKS: verificar que el cluster no esta en una subnet sin outbound connectivity
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}: {.spec.podCIDR}{"\n"}{end}'

# Verificar CNI (el plugin de red del cluster)
kubectl get pods -n kube-system | grep -E "calico|flannel|cilium|azure-cni"
```

---

## Storage Debugging

### PVC en Estado Pending

Un PersistentVolumeClaim en estado Pending significa que no ha podido ser satisfecho por ningun PersistentVolume disponible.

```bash
# Ver estado de todos los PVCs
kubectl get pvc -A
# SALIDA:
# NAMESPACE    NAME       STATUS    VOLUME   STORAGECLASS   CAPACITY
# production   data-pvc   Pending   <none>   fast-ssd       10Gi

# Diagnostico detallado
kubectl describe pvc data-pvc -n production
# Events:
#
# "no persistent volumes available for this claim and no storage class is set"
#   -> no hay PVs disponibles y no hay StorageClass configurada
#
# "waiting for first consumer to be created before binding"
#   -> la StorageClass usa volumeBindingMode: WaitForFirstConsumer
#   -> el PVC se vinculara cuando un Pod intente usarlo (comportamiento normal en AKS)
#
# "storageclass.storage.k8s.io "fast-ssd" not found"
#   -> la StorageClass no existe en el cluster
#
# "failed to provision volume with StorageClass "default":
#   rpc error: code = Internal desc = CSI driver error: ..."
#   -> error del driver CSI al crear el volumen fisico

# Verificar StorageClasses disponibles
kubectl get storageclass
# SALIDA ESPERADA EN AKS:
# NAME                    PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE
# azurefile               file.csi.azure.com   Delete          Immediate
# azurefile-csi           file.csi.azure.com   Delete          Immediate
# azurefile-csi-premium   file.csi.azure.com   Delete          Immediate
# azuredisk-csi           disk.csi.azure.com   Delete          WaitForFirstConsumer
# default (default)       disk.csi.azure.com   Delete          WaitForFirstConsumer
# managed-csi             disk.csi.azure.com   Delete          WaitForFirstConsumer
# managed-csi-premium     disk.csi.azure.com   Delete          WaitForFirstConsumer
```

---

### Fallos de Montaje de Volumenes

```bash
# El Pod esta en estado ContainerCreating por mucho tiempo
kubectl describe pod <nombre-pod>
# Events:
#
# "Multi-Attach error for volume "pvc-abc123":
#   Volume is already exclusively attached to one node
#   and can't be attached to another"
#   -> el PVC usa RWO (ReadWriteOnce) y ya esta montado en otro nodo
#   -> solucion: asegurarse de que no hay dos Pods intentando montar el mismo RWO PV
#   -> si el Pod anterior esta en Terminating, puede tardar en liberar el volumen
#
# "Unable to attach or mount volumes: unmounted volumes=[data]:
#   timed out waiting for the condition"
#   -> el CSI driver tardo demasiado en montar el volumen
#   -> puede ser un problema transitorio del proveedor de cloud (Azure Disk lento)
#   -> reiniciar el Pod o esperar y monitorear
#
# "MountVolume.SetUp failed for volume "pvc-abc123":
#   mount failed: exit status 32"
#   -> problema del sistema de archivos en el volumen
#   -> puede requerir fsck o recreacion del volumen

# Verificar estado del PV asociado
kubectl get pv
kubectl describe pv <nombre-pv>
# Buscar:
#   Status: Bound / Released / Failed
#   Claim: namespace/pvc-name

# Ver que nodo tiene montado el volumen
kubectl get volumeattachments
# SALIDA:
# NAME                                   ATTACHER               PV               NODE     ATTACHED
# csi-abc123...                          disk.csi.azure.com     pvc-xyz789...    node-2   true
```

---

## Control Plane Debugging

### API Server: El Corazon del Cluster

```bash
# Verificar salud del API server
kubectl get --raw /healthz
# SALIDA ESPERADA: ok

kubectl get --raw /readyz
# SALIDA ESPERADA: ok

kubectl get --raw /livez
# SALIDA ESPERADA: ok

# Verificar version y estado de componentes (metodo legacy, aun funcional)
kubectl get componentstatuses
# SALIDA:
# NAME                 STATUS    MESSAGE             ERROR
# scheduler            Healthy   ok
# controller-manager   Healthy   ok
# etcd-0               Healthy   {"health":"true"}

# Logs del API server (en nodo de control plane via SSH)
journalctl -u kube-apiserver -f --lines=100
# En clusters gestionados (AKS): los logs del control plane se envian a Azure Monitor
# az aks show -g <resource-group> -n <cluster-name> --query "addonProfiles"

# En AKS: ver diagnostics del control plane en Azure
# Portal -> AKS cluster -> Diagnose and solve problems -> API server
```

---

### etcd: La Base de Datos del Cluster

```bash
# Health check de etcd
kubectl exec -n kube-system etcd-<nombre-master> -- \
  etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# SALIDA ESPERADA:
# https://127.0.0.1:2379 is healthy: successfully committed proposal: took = 2.1ms

# Estado del cluster etcd (latencia, lider, etc.)
kubectl exec -n kube-system etcd-<nombre-master> -- \
  etcdctl endpoint status --write-out=table \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# SALIDA ESPERADA:
# +-------------------------+------------------+---------+---------+-----------+
# | ENDPOINT                | ID               | VERSION | DB SIZE | IS LEADER |
# +-------------------------+------------------+---------+---------+-----------+
# | https://127.0.0.1:2379  | 8e9e05c52164694d | 3.5.6   | 6.4 MB  | true      |
# +-------------------------+------------------+---------+---------+-----------+

# Notas importantes para AKS:
# En AKS, etcd es gestionado por Microsoft. No tienes acceso directo.
# Los problemas de etcd en AKS se manifiestan como:
# - API server muy lento (latencia alta)
# - kubectl commands que tardan >30s o dan timeout
# - Objetos de Kubernetes que no se actualizan
# Solucion: abrir un ticket de soporte de Azure
```

---

### Scheduler: Por Que No Se Programan los Pods

```bash
# Ver eventos de scheduling fallido
kubectl get events --field-selector reason=FailedScheduling -A
# SALIDA:
# NAMESPACE    LAST SEEN   REASON             OBJECT             MESSAGE
# production   2m          FailedScheduling   Pod/web-app-xyz    0/3 nodes are available:
#                                                                  1 Insufficient cpu,
#                                                                  2 node(s) had taint
#                                                                  {dedicated: gpu} that
#                                                                  the pod didn't tolerate.

# Ver estado del scheduler (cluster kubeadm)
kubectl get pods -n kube-system -l component=kube-scheduler
# SALIDA:
# NAME                         READY   STATUS    RESTARTS
# kube-scheduler-master-node   1/1     Running   0

# Logs del scheduler para ver decisiones de programacion
kubectl logs -n kube-system -l component=kube-scheduler --tail=50
# Buscar lineas con:
# "Attempting to schedule pod"
# "Successfully bound pod"
# "Unable to schedule pod"
```

---

## Herramientas Avanzadas de Debugging

### kubectl debug: Contenedores Efimeros

`kubectl debug` es la herramienta mas potente del arsenal de troubleshooting avanzado. Permite añadir un contenedor de diagnostico a un Pod que ya esta en ejecucion, sin necesidad de reiniciarlo ni modificar su imagen.

#### Caso 1: Depurar un Pod en Ejecucion (Ephemeral Container)

```bash
# Añadir un contenedor busybox al Pod en ejecucion para inspeccionarlo
kubectl debug pod/<nombre-pod> -it \
  --image=busybox \
  --target=<nombre-contenedor>

# Una vez dentro del contenedor efimero:
# Ver procesos del contenedor principal (si --target funciona)
ps aux

# Ver conexiones de red del contenedor
cat /proc/net/tcp

# Ver archivos del contenedor (si comparten PID namespace)
ls /proc/1/root/

# NOTA: los ephemeral containers requieren Kubernetes 1.23+
# En versiones anteriores, --target puede no funcionar
```

#### Caso 2: Depurar un Pod que Crashea Antes de Poder Entrar

Cuando un Pod crashea inmediatamente, no tienes tiempo de usar `kubectl exec`. La solucion es copiar el Pod con un comando diferente:

```bash
# Copiar el Pod con un shell en lugar del comando original
kubectl debug pod/<nombre-pod> -it \
  --copy-to=debug-pod \
  --container=<nombre-contenedor> \
  -- /bin/sh

# Esto crea un nuevo Pod llamado "debug-pod" identico al original
# pero con /bin/sh como command, dando tiempo para inspeccionar
# el sistema de archivos antes de que la app falle

# Dentro del shell debug:
# Ejecutar la aplicacion manualmente para ver el error
/app/servidor  # (o el comando original)

# Ver variables de entorno
env | sort

# Ver si los archivos de configuracion existen
ls -la /config/
cat /config/app.conf

# Limpiar al terminar
kubectl delete pod debug-pod
```

#### Caso 3: Depurar un Nodo Directamente

```bash
# Acceder al nodo con un contenedor privilegiado
kubectl debug node/<nombre-nodo> -it --image=ubuntu

# Esto crea un Pod en el nodo con acceso al filesystem del host en /host
# Una vez dentro:

# Ver el filesystem del nodo
ls /host/var/log/
ls /host/etc/kubernetes/

# Ver logs del kubelet
cat /host/var/log/kubelet.log | tail -100

# Ver logs del sistema
chroot /host journalctl -u kubelet --lines=50

# Ver contenedores en ejecucion en el nodo
chroot /host crictl ps

# Ver imagenes en el nodo
chroot /host crictl images

# Limpiar al terminar (el Pod se auto-elimina al salir)
```

---

### netshoot: La Navaja Suiza de Red

`nicolaka/netshoot` es una imagen de diagnostico de red que incluye: tcpdump, dig, nslookup, ping, traceroute, curl, wget, ss, ip, iptables, nmap, y docenas de herramientas mas.

```bash
# Lanzar netshoot como Pod temporal para diagnostico
kubectl run netshoot --rm -it \
  --image=nicolaka/netshoot \
  --restart=Never \
  -- /bin/bash

# Dentro de netshoot, las herramientas disponibles incluyen:
# tcpdump    - captura de paquetes
# dig        - consultas DNS detalladas
# nslookup   - resolucion DNS simple
# ping       - conectividad ICMP
# traceroute - ruta de red
# curl       - peticiones HTTP/HTTPS
# ss         - sockets y conexiones
# ip         - rutas y interfaces
# nmap       - escaneo de puertos
# iperf3     - pruebas de ancho de banda
# netstat    - estadisticas de red (legacy)

# Ejemplos de uso dentro de netshoot:

# Test DNS con dig (mas informacion que nslookup)
dig kubernetes.default.svc.cluster.local
# SALIDA:
# ; <<>> DiG 9.18.1 <<>> kubernetes.default.svc.cluster.local
# ;; ANSWER SECTION:
# kubernetes.default.svc.cluster.local. 30 IN A 10.96.0.1

# Traceroute a un servicio
traceroute web-service.production.svc.cluster.local
# SALIDA:
# traceroute to web-service.production.svc.cluster.local (10.96.50.200)
#  1  10.244.0.1  0.124 ms  0.089 ms  0.082 ms   <- gateway del Pod
#  2  10.96.50.200  0.201 ms  0.198 ms  0.195 ms  <- IP del Service

# Escaner de puertos a un Pod
nmap -p 80,443,8080 <pod-ip>
# SALIDA:
# PORT     STATE  SERVICE
# 80/tcp   open   http
# 443/tcp  closed https
# 8080/tcp closed http-proxy

# Prueba de ancho de banda entre Pods (requiere servidor iperf3 en el destino)
iperf3 -c <ip-destino> -p 5201 -t 10
```

---

### tcpdump: Captura de Trafico en Pods

Para diagnosticar problemas de red que no son visibles con herramientas de nivel mas alto (como logs o health checks), tcpdump permite capturar el trafico real de red que entra y sale de un contenedor.

```bash
# Metodo 1: usar kubectl debug para añadir netshoot al Pod
kubectl debug pod/<nombre-pod> -it \
  --image=nicolaka/netshoot \
  --target=<nombre-contenedor> \
  -- tcpdump -i eth0 -n -w /tmp/capture.pcap

# En otro terminal, generar trafico para capturar:
kubectl exec <nombre-pod> -- curl http://database:5432

# Ctrl+C para detener la captura

# Metodo 2: captura interactiva con filtros
kubectl debug pod/<nombre-pod> -it \
  --image=nicolaka/netshoot \
  --target=<nombre-contenedor> \
  -- tcpdump -i eth0 -n -v \
     'port 5432 or port 80'

# SALIDA ESPERADA (trafico HTTP):
# 10:15:32.123456 IP 10.244.1.15.56789 > 10.96.50.200.80:
#   Flags [S], seq 1234567890, length 0
# 10:15:32.124001 IP 10.96.50.200.80 > 10.244.1.15.56789:
#   Flags [S.], seq 987654321, ack 1234567891, length 0
# <- se ve el TCP handshake -> conexion establecida correctamente

# SALIDA SI LA CONEXION ES RECHAZADA:
# 10:15:32.123456 IP 10.244.1.15.56789 > 10.96.50.200.5432:
#   Flags [S], seq 1234567890, length 0
# 10:15:32.124001 IP 10.96.50.200.5432 > 10.244.1.15.56789:
#   Flags [R.], seq 0, ack 1234567891, length 0
# <- RST significa rechazo -> el puerto no esta escuchando o hay firewall

# Capturar solo errores DNS
kubectl debug pod/<nombre-pod> -it \
  --image=nicolaka/netshoot \
  --target=<nombre-contenedor> \
  -- tcpdump -i eth0 -n 'udp port 53'
# Ver si las consultas DNS llegan y si hay respuesta NXDOMAIN o SERVFAIL
```

---

## Laboratorio 4.5: Troubleshooting Practico

### Paso 1: Crear Aplicacion con Problemas

```bash
# Aplicacion con problemas intencionados
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: problematic-app
  namespace: desarrollo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: problematic-app
  template:
    metadata:
      labels:
        app: problematic-app
    spec:
      containers:
      - name: app
        image: nginx:1.21
        resources:
          requests:
            cpu: 2000m  # Recurso excesivo
            memory: 4Gi
          limits:
            cpu: 2000m
            memory: 4Gi
        readinessProbe:
          httpGet:
            path: /nonexistent  # Path que no existe
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
EOF
```

### Paso 2: Diagnosticar Problemas

```bash
# Ver estado de pods
kubectl get pods -n desarrollo -l app=problematic-app

# Describir pod problematico
POD_NAME=$(kubectl get pods -n desarrollo -l app=problematic-app -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD_NAME -n desarrollo

# Ver eventos
kubectl get events -n desarrollo --sort-by=.metadata.creationTimestamp | tail -10

# Verificar recursos disponibles
kubectl top nodes
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### Paso 3: Corregir Problemas

```bash
# Corregir configuracion
cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: problematic-app
  namespace: desarrollo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: problematic-app
  template:
    metadata:
      labels:
        app: problematic-app
    spec:
      containers:
      - name: app
        image: nginx:1.21
        resources:
          requests:
            cpu: 100m  # Recurso razonable
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
        readinessProbe:
          httpGet:
            path: /  # Path correcto
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
EOF

# Verificar correccion
kubectl get pods -n desarrollo -l app=problematic-app
kubectl rollout status deployment/problematic-app -n desarrollo
```

### Paso 4: Debugging con kubectl debug

```bash
# Crear un Pod con un error de inicio deliberado para practicar debugging
kubectl run crashing-app \
  --image=busybox \
  --restart=Always \
  -- sh -c 'echo "intentando conectar a DB..."; sleep 2; exit 1'

# Observar el CrashLoopBackOff
kubectl get pod crashing-app -w
# SALIDA:
# NAME           READY   STATUS              RESTARTS   AGE
# crashing-app   0/1     ContainerCreating   0          3s
# crashing-app   0/1     Error               0          5s
# crashing-app   0/1     CrashLoopBackOff    1          7s
# crashing-app   0/1     CrashLoopBackOff    2          20s

# Ver los logs del contenedor caido
kubectl logs crashing-app --previous
# SALIDA:
# intentando conectar a DB...

# Describir para ver el exit code
kubectl describe pod crashing-app
# Last State: Terminated, Reason: Error, Exit Code: 1

# Copiar el Pod con un shell para inspeccionar
kubectl debug pod/crashing-app -it \
  --copy-to=debug-crashing \
  --container=crashing-app \
  -- /bin/sh
# Ahora puedes explorar el contenedor: ver filesystem, env vars, etc.

# Limpiar
kubectl delete pod crashing-app debug-crashing
```

### Paso 5: Diagnostico de DNS

```bash
# Test completo de DNS
kubectl run dns-test --rm -it --image=busybox:1.28 --restart=Never -- \
  sh -c 'nslookup kubernetes.default && nslookup google.com'

# SALIDA ESPERADA (DNS interno y externo funcionando):
# Server:    10.96.0.10
# Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
# Name:      kubernetes.default
# Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local
#
# Server:    10.96.0.10
# Name:      google.com
# Address 1: 142.250.185.46 mad41s10-in-f14.1e100.net

# Diagnose CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### Paso 6: Diagnostico de Red con netshoot

```bash
# Lanzar netshoot para diagnostico de red
kubectl run netshoot --rm -it \
  --image=nicolaka/netshoot \
  --restart=Never \
  -- /bin/bash

# Dentro de netshoot:
# 1. Test DNS
dig kubernetes.default.svc.cluster.local +short
# SALIDA ESPERADA: 10.96.0.1

# 2. Test conectividad al API server
curl -k https://kubernetes.default/healthz
# SALIDA ESPERADA: ok

# 3. Traceroute a un service
traceroute kubernetes.default.svc.cluster.local

# 4. Ver tabla de rutas
ip route show

# Salir con: exit
```

---

## Tabla de Referencia Rapida: Troubleshooting

| Sintoma | Primer Comando | Causa Comun | Solucion Rapida |
|---------|---------------|-------------|-----------------|
| Pod Pending | `kubectl describe pod` | Recursos insuficientes | Reducir requests o añadir nodos |
| Pod Pending | `kubectl describe pod` | NodeSelector sin match | Añadir label al nodo o corregir selector |
| Pod Pending | `kubectl describe pod` | Taint sin toleration | Añadir toleration al Pod |
| Pod Pending | `kubectl describe pvc` | PVC no bound | Verificar StorageClass y PVs disponibles |
| CrashLoopBackOff | `kubectl logs --previous` | Error en la app (exit 1) | Ver logs, corregir la aplicacion |
| CrashLoopBackOff | `kubectl describe pod` | OOMKilled (exit 137) | Aumentar memory limit |
| CrashLoopBackOff | `kubectl describe pod` | Comando no encontrado (exit 127) | Corregir command/args |
| ImagePullBackOff | `kubectl describe pod` | Imagen no existe | Verificar nombre y tag |
| ImagePullBackOff | `kubectl describe pod` | Registry privado | Crear imagePullSecret |
| OOMKilled | `kubectl describe pod` | Limite de memoria excedido | Aumentar limits o corregir memory leak |
| Node NotReady | `kubectl describe node` | kubelet detenido | `systemctl restart kubelet` |
| Node NotReady | `kubectl describe node` | DiskPressure | `crictl rmi --prune`, limpiar logs |
| Node NotReady | `kubectl describe node` | MemoryPressure | Desalojar Pods BestEffort |
| Service no resuelve | `kubectl get endpoints` | Selector mismatch | Corregir labels en Pods o selector en Service |
| DNS falla | `kubectl get pods -n kube-system` | CoreDNS caido | Reiniciar CoreDNS Pods |
| PVC Pending | `kubectl describe pvc` | StorageClass no existe | Crear StorageClass o corregir nombre |
| PVC Pending | `kubectl describe pvc` | No hay PVs disponibles | Crear PV manualmente o usar StorageClass con provisioner |
| Volume mount timeout | `kubectl describe pod` | RWO ya montado en otro nodo | Esperar liberacion o cambiar a RWX |
| API server lento | `kubectl get --raw /healthz` | etcd con latencia alta | Revisar disco de etcd, contactar soporte (AKS) |
| Pods no programados | `kubectl get events --field-selector reason=FailedScheduling` | Scheduler con problema | Revisar logs del scheduler |

---

## Resumen del Capitulo

El troubleshooting sistematico sigue un flujo: identificar, recopilar informacion, analizar, probar hipotesis e implementar solucion. Los comandos clave son `kubectl describe`, `kubectl logs --previous`, `kubectl get events` y `kubectl exec`. Los tres escenarios mas comunes — Pending (recursos insuficientes), CrashLoopBackOff (error en la app o health checks) y problemas de conectividad (DNS o Network Policies) — cubren la mayoria de incidentes en produccion.

### Framework de 4 Capas

El framework sistematico de 4 capas (Aplicacion -> Pod -> Nodo -> Cluster) garantiza que siempre buscas la causa raiz en el lugar correcto. Empieza por lo mas cercano al usuario y baja solo cuando has descartado la capa superior.

### Exit Codes Como Guia

Los codigos de salida son la primera pista en cualquier CrashLoopBackOff:
- **137**: OOMKilled — el proceso fue matado por falta de memoria
- **1**: error generico de aplicacion — revisar logs
- **127**: comando no encontrado — revisar command/args
- **143**: SIGTERM — terminacion externa, puede ser normal en actualizaciones

### Herramientas de Nivel Avanzado

- **kubectl debug**: contenedores efimeros para inspeccionar Pods en ejecucion o que crashean antes de poder inspeccionarlos
- **nicolaka/netshoot**: imagen de diagnostico de red con tcpdump, dig, traceroute, nmap y docenas de herramientas mas
- **tcpdump en Pods**: captura el trafico real de red para diagnosticar problemas que los logs de aplicacion no revelan
- **kubectl debug node/**: acceso al filesystem del nodo con permisos elevados para diagnosticar problemas de kubelet y container runtime

### Los Numeros Que Importan

- El backoff de CrashLoopBackOff llega a 5 minutos entre reinicios — usa `kubectl logs --previous` en lugar de esperar
- La eviction por MemoryPressure desaloja en orden: BestEffort primero, Guaranteed ultimo
- DNS en Kubernetes usa el formato `servicio.namespace.svc.cluster.local` para comunicacion entre namespaces
- Exit code 137 = OOMKilled, exit code 1 = error de app, exit code 127 = binario no encontrado
