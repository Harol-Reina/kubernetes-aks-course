# Lab Resumen: Arquitectura del Cluster

Laboratorio guiado de 60 minutos sobre los componentes clave de la arquitectura de Kubernetes,
disenado para ejecutarse en Minikube. Ideal para quienes aprenden Kubernetes por primera vez
o quieren repasar antes de un examen CKAD/CKA.

**Duracion:** 60 minutos | **Nivel:** Principiante

---

## Conceptos Cubiertos

| Componente | Concepto demostrado |
|------------|---------------------|
| API Server | Punto de entrada de todos los manifests y peticiones kubectl |
| kube-scheduler | Asignacion de Pods a nodos segun recursos y nodeSelector |
| kubelet | Gestion de ciclo de vida del contenedor y ejecucion de probes |
| kube-proxy | Implementacion de Services con iptables/IPVS y NetworkPolicy |
| Container Runtime | Ejecucion real de contenedores (containerd/CRI-O) |

## Archivo del Lab

| Archivo | Descripcion |
|---------|-------------|
| `arquitectura-lab.yaml` | YAML unico con todos los recursos del lab |

---

## Conceptos Previos Necesarios

Antes de comenzar, necesitas entender dos ideas basicas. No te preocupes si son nuevas —
las explicamos brevemente aqui.

### ¿Que es un contenedor?

Un **contenedor** es una forma de empaquetar una aplicacion junto con todo lo que necesita
para funcionar (librerias, configuracion, dependencias) en una unidad portatil y aislada.
Puedes pensar en un contenedor como una "caja estandarizada" — igual que los contenedores
de barco permiten transportar cualquier tipo de carga sin importar el barco, los contenedores
de software permiten ejecutar cualquier aplicacion sin importar el servidor.

La tecnologia que crea y ejecuta estos contenedores se llama **Docker** (o en terminos mas
generales, un "container runtime").

### ¿Para que sirve Kubernetes?

Cuando tienes muchos contenedores — decenas, cientos, miles — necesitas algo que los organice:
que decida donde ejecutarlos, que los reinicie si fallan, que distribuya el trafico entre ellos,
etc. Eso es exactamente lo que hace **Kubernetes**: es el sistema que gestiona y orquesta
contenedores a gran escala.

La analogia mas util: **un cluster de Kubernetes es como una empresa**.

- La empresa tiene una **sede central** (el Control Plane) donde estan los directivos
  que toman decisiones.
- La empresa tiene **sucursales** (los Nodes trabajadores) donde el trabajo real se realiza.
- Los **empleados** que trabajan en las sucursales son los contenedores que ejecutan
  tus aplicaciones.

---

## Introduccion: ¿Que es la Arquitectura del Cluster?

Un **cluster de Kubernetes** esta formado por un conjunto de maquinas (fisicas o virtuales)
que trabajan juntas. Estas maquinas se dividen en dos roles:

```
┌─────────────────────────────────────────────────────────┐
│                   CLUSTER DE KUBERNETES                  │
│                                                          │
│  ┌──────────────────────┐   ┌────────────────────────┐  │
│  │   CONTROL PLANE      │   │   WORKER NODES         │  │
│  │   (La sede central)  │   │   (Las sucursales)     │  │
│  │                      │   │                        │  │
│  │  - API Server        │   │  - kubelet             │  │
│  │  - etcd              │   │  - kube-proxy          │  │
│  │  - Scheduler         │   │  - Container Runtime   │  │
│  │  - Controller Manager│   │  - Pods (contenedores) │  │
│  └──────────────────────┘   └────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

**Control Plane** = el "cerebro" del cluster. Aqui viven los componentes que toman
decisiones: donde ejecutar cada contenedor, cuantas copias mantener, etc.

**Worker Node** = las maquinas donde realmente corren tus aplicaciones (tus contenedores).
En este lab usamos Minikube, que combina ambos roles en una sola maquina virtual para
facilitar el aprendizaje local.

### ¿Por que importa entender esto?

Cuando algo falla en Kubernetes, saber que componente es responsable de cada cosa te permite
diagnosticar el problema rapidamente. Si un Pod no arranca, puede ser culpa del Scheduler
(no encontro un nodo), del kubelet (no pudo descargar la imagen), o del container runtime
(no pudo crear el contenedor). Sin este mapa mental, el troubleshooting es mucho mas dificil.

---

## Paso 1: Desplegar todos los recursos (2 minutos)

Antes de desplegar, vamos a entender QUE vamos a crear. El archivo `arquitectura-lab.yaml`
contiene varios recursos que demuestran cada componente del cluster:

- Un **Namespace** llamado `lab-arquitectura-test` — un espacio de trabajo aislado dentro
  del cluster, como una carpeta que agrupa recursos relacionados.
- Un **Deployment** con 3 replicas de nginx — demuestra como el Scheduler y kubelet
  colaboran para mantener Pods en ejecucion.
- Un **Service** ClusterIP — demuestra como kube-proxy enruta trafico hacia los Pods.
- Un **Pod** con nodeSelector — demuestra la decision de scheduling del kube-scheduler.
- Un **Pod** con livenessProbe — demuestra como kubelet monitorea la salud de los contenedores.
- Una **NetworkPolicy** — demuestra las politicas de red implementadas por el CNI.
- Un **Pod** netshoot — herramienta de diagnostico de red que usaremos para probar conectividad.

```bash
kubectl apply -f arquitectura-lab.yaml
```

**Salida esperada:**
```
namespace/lab-arquitectura-test created
deployment.apps/web-app created
service/web-app-svc created
pod/scheduler-demo created
pod/kubelet-demo created
networkpolicy.networking.k8s.io/frontend-only created
pod/netshoot created
```

**¿Que significa esta salida?**

Cada linea confirma que el API Server recibio tu solicitud, valido el YAML y guardo el recurso
en etcd (la base de datos del cluster). En este momento los recursos existen "en papel" pero
los contenedores pueden no estar corriendo todavia — el Scheduler y kubelet aun estan trabajando
para materializarlos.

Espera 20-30 segundos para que todos los contenedores arranquen, luego verifica:

```bash
kubectl get pods -n lab-arquitectura-test
```

**Salida esperada (todos en Running):**
```
NAME                       READY   STATUS    RESTARTS   AGE
kubelet-demo               1/1     Running   0          30s
netshoot                   1/1     Running   0          30s
scheduler-demo             1/1     Running   0          30s
web-app-6d4b9f8b7c-abc12   1/1     Running   0          30s
web-app-6d4b9f8b7c-def34   1/1     Running   0          30s
web-app-6d4b9f8b7c-ghi56   1/1     Running   0          30s
```

**¿Que significa `1/1 Running`?**

- `1/1` significa que 1 contenedor de 1 posibles esta listo (Ready). Si fuera `0/1` significaria
  que el contenedor existe pero no esta listo aun.
- `Running` es el estado del Pod — indica que el contenedor esta ejecutandose normalmente.
- `RESTARTS: 0` confirma que el contenedor nunca ha necesitado reiniciarse, lo cual es buena senal.

### ¿Que acabamos de aprender?

El simple comando `kubectl apply -f` desencadeno una cadena de eventos que involucra
a TODOS los componentes del Control Plane: el API Server recibio la solicitud, la guardo en
etcd, el Scheduler asigno cada Pod a un nodo, y el kubelet en ese nodo le ordeno al container
runtime que iniciara los contenedores.

---

## Paso 2: Demostrar el API Server (5 minutos)

### ¿Que es el API Server?

El **API Server** (kube-apiserver) es como la **recepcion de un edificio**: absolutamente
todo lo que quieras hacer en el cluster — crear un Pod, borrar un Deployment, consultar logs —
pasa obligatoriamente por el API Server. El no ejecuta nada por si mismo, pero valida cada
solicitud, la autentifica, la autoriza, y la persiste en etcd.

Cuando tu ejecutas `kubectl apply -f algo.yaml`, kubectl no hace magia: simplemente empaqueta
tu YAML en una peticion HTTPS y la envia al API Server. Cualquier herramienta que hable
con Kubernetes — `kubectl`, dashboards, pipelines de CI/CD — hace exactamente lo mismo.

```bash
# Ver la URL del API Server (donde kubectl envia sus peticiones)
kubectl cluster-info
```

**Salida esperada:**
```
Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/...
```

**¿Que significa esto?**

La URL `https://192.168.49.2:8443` es la direccion del API Server de Minikube. Cada vez
que ejecutas un comando `kubectl`, este se conecta a esa URL. La comunicacion es siempre
por HTTPS (cifrada) y requiere autenticacion (el certificado en tu archivo `~/.kube/config`).

```bash
# Obtener la URL del API Server en una variable
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
echo "API Server: $API_SERVER"

# Verificar la salud del API Server directamente (sin pasar por kubectl)
kubectl get --raw /healthz
```

**Salida esperada de `/healthz`:**
```
ok
```

**¿Que significa esto?**

`/healthz` es un endpoint especial del API Server que responde `ok` cuando esta funcionando
correctamente. Es el equivalente de tocar una puerta y que alguien responda — si no hay
respuesta, el cluster tiene un problema grave.

```bash
# Ver todos los recursos del lab (confirma que el API Server proceso nuestro YAML)
kubectl get all -n lab-arquitectura-test
```

**Salida esperada:**
```
NAME                           READY   STATUS    RESTARTS   AGE
pod/kubelet-demo               1/1     Running   0          2m
pod/netshoot                   1/1     Running   0          2m
pod/scheduler-demo             1/1     Running   0          2m
pod/web-app-xxx-yyy            1/1     Running   0          2m

NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/web-app-svc   ClusterIP   10.96.xxx.xxx   <none>        80/TCP    2m

NAME                     READY   UP-TO-DATE   AVAILABLE   REPLICAS   AGE
deployment.apps/web-app  3/3     3            3           3          2m

NAME                                DESIRED   CURRENT   READY   AGE
replicaset.apps/web-app-xxx         3         3         3       2m
```

**¿Que significa la columna CLUSTER-IP?**

La `CLUSTER-IP` es una IP virtual que solo existe dentro del cluster. No puedes conectarte
a ella desde tu laptop directamente. Esta IP es gestionada por kube-proxy y permite que
otros Pods dentro del cluster encuentren tu aplicacion por una IP estable, incluso si
los Pods individuales se reinician y cambian de IP.

### ¿Que acabamos de aprender?

El API Server es el unico punto de entrada al cluster. Valida, autentica y persiste toda
solicitud. El endpoint `/healthz` confirma que esta operativo. Todo lo que existe en el
cluster fue creado a traves del API Server.

---

## Paso 3: Demostrar el Scheduler (8 minutos)

### ¿Que es el kube-scheduler?

El **kube-scheduler** es como el **jefe de recursos humanos** de la empresa: cuando hay un
trabajo nuevo que hacer (un Pod nuevo), el decide que sucursal (Node) tiene capacidad y
es el mas adecuado para realizarlo. Una vez que el Scheduler toma esa decision, la registra
en el API Server y el kubelet del nodo elegido se encarga del resto.

El Scheduler evalua varios criterios al elegir un nodo:
- Recursos disponibles (CPU y memoria libres en cada nodo)
- Restricciones explicitas del Pod (`nodeSelector`, `affinity`, `taints/tolerations`)
- Politicas de distribucion (intentar no poner todos los Pods en el mismo nodo)

En este lab, el Pod `scheduler-demo` tiene un `nodeSelector` que dice "solo ejecutame
en nodos con sistema operativo Linux". En Minikube (que solo tiene un nodo Linux), siempre
va al unico nodo disponible.

```bash
# Ver en que nodo asigno el Scheduler cada Pod (columna NODE)
kubectl get pods -n lab-arquitectura-test -o wide
```

**Salida esperada:**
```
NAME                       READY   STATUS    RESTARTS   AGE   IP            NODE       ...
kubelet-demo               1/1     Running   0          3m    10.244.0.5    minikube   ...
netshoot                   1/1     Running   0          3m    10.244.0.6    minikube   ...
scheduler-demo             1/1     Running   0          3m    10.244.0.4    minikube   ...
web-app-xxx-yyy            1/1     Running   0          3m    10.244.0.7    minikube   ...
```

**¿Que significa la columna NODE?**

Muestra en que maquina fisica o virtual esta corriendo cada Pod. En Minikube todos van
al mismo nodo (`minikube`) porque solo hay uno. En un cluster de produccion veras distintos
nombres de nodo — el Scheduler habra distribuido los Pods inteligentemente entre ellos.

La columna IP muestra la IP interna del Pod dentro del cluster. Cada Pod recibe su propia IP.

```bash
# Ver el evento de scheduling — el momento exacto en que el Scheduler tomo su decision
kubectl get events -n lab-arquitectura-test \
  --field-selector involvedObject.name=scheduler-demo \
  --sort-by='.lastTimestamp'
```

**Salida esperada:**
```
LAST SEEN   TYPE     REASON      OBJECT                MESSAGE
Xs          Normal   Scheduled   pod/scheduler-demo    Successfully assigned lab-arquitectura-test/scheduler-demo to minikube
Xs          Normal   Pulling     pod/scheduler-demo    Pulling image "nginx:1.25"
Xs          Normal   Pulled      pod/scheduler-demo    Successfully pulled image "nginx:1.25"
Xs          Normal   Created     pod/scheduler-demo    Created container nginx
Xs          Normal   Started     pod/scheduler-demo    Started container nginx
```

**¿Que nos dice esta secuencia de eventos?**

Este es el ciclo de vida completo de un Pod desde que el Scheduler lo acepta:

1. `Scheduled` — El Scheduler eligio el nodo `minikube`.
2. `Pulling` — El kubelet en ese nodo le ordeno al container runtime que descargue la imagen.
3. `Pulled` — La imagen se descargo correctamente.
4. `Created` — El container runtime creo el contenedor.
5. `Started` — El contenedor comenzo a ejecutarse.

```bash
# Confirmar el nodeSelector que el Scheduler tuvo en cuenta
kubectl get pod scheduler-demo -n lab-arquitectura-test \
  -o jsonpath='{.spec.nodeSelector}' && echo
```

**Salida esperada:**
```
{"kubernetes.io/os":"linux"}
```

**¿Que significa esto?**

El `nodeSelector` `kubernetes.io/os: linux` es una restriccion que le dice al Scheduler:
"solo ponme en nodos que tengan la etiqueta `kubernetes.io/os=linux`". Todos los nodos Linux
tienen esta etiqueta automaticamente. Si hubiera pedido `kubernetes.io/os: windows`, el
Scheduler buscaria un nodo Windows, y si no hay ninguno, el Pod quedaria en estado `Pending`.

### ¿Que acabamos de aprender?

El Scheduler es el responsable de decidir DONDE vive cada Pod. Toma esa decision una sola vez,
al momento de crear el Pod. Los eventos del Pod registran toda esa historia. El `nodeSelector`
es la forma mas simple de influir en esa decision.

---

## Paso 4: Demostrar kubelet (8 minutos)

### ¿Que es kubelet?

**kubelet** es como el **supervisor de cada sucursal**: una vez que el Scheduler decide que
un Pod va a un nodo especifico, kubelet (que corre en ese nodo) se encarga de todo lo demas.
Recibe la especificacion del Pod del API Server, le dice al container runtime que inicie el
contenedor, y luego lo vigila continuamente ejecutando "health checks" (llamados **probes**).

Si una probe detecta que el contenedor no esta respondiendo correctamente, kubelet lo
reinicia automaticamente. Esta es una de las capacidades de auto-recuperacion mas importantes
de Kubernetes.

Hay tres tipos de probes:
- **livenessProbe**: "¿Esta vivo este contenedor?" Si falla, kubelet lo reinicia.
- **readinessProbe**: "¿Esta listo para recibir trafico?" Si falla, se saca del Service.
- **startupProbe**: "¿Ya termino de arrancar?" Util para aplicaciones lentas en iniciar.

```bash
# Ver la livenessProbe configurada en kubelet-demo
kubectl describe pod kubelet-demo -n lab-arquitectura-test | grep -A 8 "Liveness:"
```

**Salida esperada:**
```
Liveness:   http-get http://:80/ delay=10s timeout=1s period=10s #success=1 #failure=3
```

**¿Que significa cada parte?**

- `http-get http://:80/` — kubelet hace una peticion HTTP GET al puerto 80 del contenedor.
- `delay=10s` — espera 10 segundos despues de que el contenedor arranca antes de empezar
  a verificar (para darle tiempo de inicializarse).
- `period=10s` — verifica cada 10 segundos.
- `timeout=1s` — si el contenedor no responde en 1 segundo, cuenta como fallo.
- `#failure=3` — necesita 3 fallos consecutivos para considerar el contenedor "muerto"
  y reiniciarlo. Esto evita reinicios por fallos transitorios.

```bash
# Ver el historial de eventos de kubelet-demo (arrranque del contenedor)
kubectl get events -n lab-arquitectura-test \
  --field-selector involvedObject.name=kubelet-demo \
  --sort-by='.lastTimestamp'
```

**Salida esperada:**
```
LAST SEEN   TYPE     REASON    OBJECT              MESSAGE
Xs          Normal   Scheduled pod/kubelet-demo    Successfully assigned ...
Xs          Normal   Pulling   pod/kubelet-demo    Pulling image "nginx:1.25"
Xs          Normal   Pulled    pod/kubelet-demo    Successfully pulled image "nginx:1.25"
Xs          Normal   Created   pod/kubelet-demo    Created container nginx
Xs          Normal   Started   pod/kubelet-demo    Started container nginx
```

```bash
# Ver cuantas veces ha reiniciado el contenedor (debe ser 0 si la probe es exitosa)
kubectl get pod kubelet-demo -n lab-arquitectura-test \
  -o jsonpath='{.status.containerStatuses[0].restartCount}' && echo
```

**Salida esperada:**
```
0
```

**¿Que significa `restartCount: 0`?**

Significa que desde que el Pod arranco, kubelet nunca ha necesitado reiniciar el contenedor.
La livenessProbe esta pasando en cada verificacion — nginx esta respondiendo correctamente
en el puerto 80. Si el valor fuera mayor que 0, indicaria que el contenedor ha fallado
y sido reiniciado. Un valor que sigue creciendo con el tiempo indica un problema cronico
(en Kubernetes esto se llama un "CrashLoopBackOff").

### ¿Que acabamos de aprender?

kubelet es el guardian de cada Pod en su nodo. Ejecuta las health probes periodicamente y
reinicia automaticamente los contenedores que fallan. Ver `RESTARTS: 0` en `kubectl get pods`
confirma que kubelet esta satisfecho con el estado de los contenedores.

---

## Paso 5: Demostrar kube-proxy y Services (8 minutos)

### ¿Que es kube-proxy?

**kube-proxy** es como el **sistema de centralita de telefono** de la empresa: cuando alguien
llama a un numero general (la ClusterIP del Service), kube-proxy decide a que extension
(Pod especifico) transferir la llamada.

Tecnicamente, kube-proxy programa reglas en `iptables` (o `IPVS`) de cada nodo. Cuando
un Pod intenta conectarse a la ClusterIP de un Service, el kernel del sistema operativo
intercepta esa conexion y la redirige a uno de los Pods reales, balanceando la carga.

```bash
# Ver la ClusterIP asignada al Service
kubectl get svc web-app-svc -n lab-arquitectura-test
```

**Salida esperada:**
```
NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
web-app-svc   ClusterIP   10.96.xxx.xxx   <none>        80/TCP    5m
```

**¿Que es la CLUSTER-IP?**

Es una IP virtual estable que representa al Service. Esta IP nunca cambia mientras el
Service exista. Los Pods individuales detras del Service si pueden cambiar — si uno muere
y nace uno nuevo con diferente IP, el Service sigue siendo accesible en la misma CLUSTER-IP.
Esto es lo que hace a los Services tan utiles: abstraen la volatilidad de los Pods.

```bash
# Ver los Endpoints — las IPs reales de los Pods detras del Service
kubectl get endpoints web-app-svc -n lab-arquitectura-test
```

**Salida esperada:**
```
NAME          ENDPOINTS                                            AGE
web-app-svc   10.244.0.5:80,10.244.0.6:80,10.244.0.7:80         5m
```

**¿Que son los Endpoints?**

Los Endpoints son la lista de IPs y puertos de los Pods que actualmente tienen el label
`app: web-app` y estan en estado Ready. kube-proxy usa esta lista para saber a donde
redirigir el trafico. Si un Pod muere, su IP desaparece de esta lista automaticamente.

```bash
# Desde el pod netshoot, conectarse al Service usando su NOMBRE (DNS)
# En lugar de la IP, usamos el nombre "web-app-svc" — Kubernetes resuelve el nombre automaticamente
kubectl exec -n lab-arquitectura-test netshoot -- curl -s http://web-app-svc | head -5
```

**Salida esperada:**
```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

**¿Por que funciona usar el nombre en lugar de la IP?**

Kubernetes incluye un componente llamado **CoreDNS** que actua como servidor DNS interno
del cluster. Cuando un Pod hace una peticion a `web-app-svc`, CoreDNS resuelve ese nombre
a la ClusterIP del Service. Luego kube-proxy redirige esa conexion a uno de los Pods reales.
Es el mismo principio que cuando escribes `google.com` en el navegador — el DNS resuelve
el nombre a una IP numerica.

```bash
# Ver la NetworkPolicy (politica de red gestionada por el CNI, no por kube-proxy directamente)
kubectl get networkpolicy -n lab-arquitectura-test
```

**Salida esperada:**
```
NAME            POD-SELECTOR   AGE
frontend-only   app=web-app    5m
```

```bash
# El pod netshoot tiene label tier=frontend, por lo que puede acceder
# (la NetworkPolicy solo permite acceso a pods con ese label)
kubectl exec -n lab-arquitectura-test netshoot -- curl -s --max-time 3 http://web-app-svc
```

**Salida esperada:** La pagina de bienvenida de nginx (igual que antes).

**¿Que demuestra esto?**

La NetworkPolicy `frontend-only` dice: "solo permitas trafico hacia los Pods `app=web-app`
si el Pod origen tiene el label `tier=frontend`". El Pod netshoot tiene ese label, por lo
tanto puede conectarse. Un Pod sin ese label seria rechazado — el trafico simplemente
no llegaria, sin ningun mensaje de error explicito, solo un timeout.

### ¿Que acabamos de aprender?

kube-proxy hace que los Services funcionen programando reglas de red en cada nodo. La
ClusterIP es una IP virtual estable que oculta la complejidad de los Pods efimeros detras
de ella. Los nombres DNS de Services funcionan gracias a CoreDNS. Las NetworkPolicies
anade una capa de control sobre quien puede hablar con quien.

---

## Paso 6: Demostrar el Container Runtime (5 minutos)

### ¿Que es el Container Runtime?

El **container runtime** es el componente que realmente crea y ejecuta los contenedores.
Es el "motor" debajo del capo. kubelet decide QUE hacer (iniciar, detener, verificar un
contenedor) pero el container runtime es el que HACE ese trabajo.

Los container runtimes mas comunes son:
- **containerd** — el mas usado hoy en dia, fue extraido de Docker
- **CRI-O** — alternativa ligera orientada a Kubernetes
- **Docker Engine** — ya no es compatible directamente con Kubernetes moderno

kubelet se comunica con el runtime a traves de una interfaz estandar llamada **CRI**
(Container Runtime Interface). Esta interfaz permite que kubelet funcione con cualquier
runtime sin cambiar su propio codigo.

```bash
# Ver que container runtime esta usando cada Node del cluster
kubectl get nodes -o wide
```

**Salida esperada:**
```
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP    ...   CONTAINER-RUNTIME
minikube   Ready    control-plane   10m   v1.28.x   192.168.49.2   ...   containerd://1.7.x
```

**¿Que significa la columna CONTAINER-RUNTIME?**

Muestra el runtime instalado en ese nodo y su version. `containerd://1.7.x` significa que
este nodo usa containerd version 1.7.x. En un cluster de produccion en AKS (Azure), por
defecto tambien se usa containerd.

```bash
# Ver que imagen usa cada Pod (la imagen es lo que el runtime descargo y ejecuta)
kubectl get pods -n lab-arquitectura-test \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].image}{"\n"}{end}'
```

**Salida esperada:**
```
kubelet-demo    nginx:1.25
netshoot        nicolaka/netshoot:latest
scheduler-demo  nginx:1.25
web-app-xxx     nginx:1.25
web-app-yyy     nginx:1.25
web-app-zzz     nginx:1.25
```

**¿Que significa cada imagen?**

- `nginx:1.25` — el servidor web nginx, version 1.25. Es una imagen publica de Docker Hub.
- `nicolaka/netshoot` — una imagen de herramientas de diagnostico de red. La usamos para
  hacer `curl` desde dentro del cluster en el Paso 5.

```bash
# Ver el estado detallado del primer Pod del Deployment (como lo ve kubelet)
kubectl get pods -n lab-arquitectura-test -l app=web-app -o name | head -1 | \
  xargs kubectl describe -n lab-arquitectura-test
```

Busca en la salida la seccion `Container ID` — tendras algo como:
```
Container ID: containerd://abc123def456...
```

Ese ID largo es la referencia interna del container runtime al contenedor especifico.
kubelet usa ese ID para hablar con containerd cuando necesita, por ejemplo, detener
ese contenedor especifico.

### ¿Que acabamos de aprender?

El container runtime es la capa final que materializa los contenedores. kubelet le da
ordenes via CRI, y containerd (o CRI-O) ejecuta la imagen descargada y crea el proceso
del contenedor. Sin el container runtime, Kubernetes no podria ejecutar nada.

---

## Paso 7: Verificacion Final (5 minutos)

Este paso integra todo lo que hemos visto. Vamos a hacer un resumen del estado de todos
los componentes que demostramos.

```bash
# Ver todos los recursos del lab en un solo comando
kubectl get all,networkpolicy -n lab-arquitectura-test
```

**Salida esperada (todos los recursos en estado correcto):**
```
NAME                           READY   STATUS    RESTARTS   AGE
pod/kubelet-demo               1/1     Running   0          15m
pod/netshoot                   1/1     Running   0          15m
pod/scheduler-demo             1/1     Running   0          15m
pod/web-app-xxx-yyy            1/1     Running   0          15m
pod/web-app-xxx-zzz            1/1     Running   0          15m
pod/web-app-xxx-aaa            1/1     Running   0          15m

NAME                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/web-app-svc   ClusterIP   10.96.xx.xx    <none>        80/TCP    15m

NAME                     READY   UP-TO-DATE   AVAILABLE   REPLICAS   AGE
deployment.apps/web-app  3/3     3            3           3          15m

NAME                        DESIRED   CURRENT   READY   AGE
replicaset.apps/web-app-xxx 3         3         3       15m

NAME                                         POD-SELECTOR   AGE
networkpolicy.networking.k8s.io/frontend-only app=web-app   15m
```

```bash
# Resumen de componentes observados en este lab
echo "=== Verificacion de Componentes Kubernetes ==="
echo "API Server:       $(kubectl get --raw /healthz)"
echo "Scheduler:        Pod scheduler-demo en nodo '$(kubectl get pod scheduler-demo -n lab-arquitectura-test -o jsonpath='{.spec.nodeName}')'"
echo "kubelet probes:   $(kubectl get pod kubelet-demo -n lab-arquitectura-test -o jsonpath='{.status.containerStatuses[0].restartCount}') reinicios (0 = sano)"
echo "kube-proxy svc:   ClusterIP $(kubectl get svc web-app-svc -n lab-arquitectura-test -o jsonpath='{.spec.clusterIP}')"
echo "Runtime:          $(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.containerRuntimeVersion}')"
```

**Salida esperada:**
```
=== Verificacion de Componentes Kubernetes ===
API Server:       ok
Scheduler:        Pod scheduler-demo en nodo 'minikube'
kubelet probes:   0 reinicios (0 = sano)
kube-proxy svc:   ClusterIP 10.96.xxx.xxx
Runtime:          containerd://1.7.x
```

**¿Que nos confirma este resumen?**

- `API Server: ok` — el Control Plane esta operativo y acepta solicitudes.
- `en nodo 'minikube'` — el Scheduler asigno correctamente el Pod al unico nodo disponible.
- `0 reinicios` — kubelet no ha necesitado reiniciar el contenedor; las probes pasan.
- `ClusterIP 10.96.xxx.xxx` — kube-proxy mantiene un Service funcional en esa IP virtual.
- `containerd://1.7.x` — el container runtime esta instalado y en uso.

### ¿Que acabamos de aprender en todo el lab?

Has observado en accion los 5 componentes clave de Kubernetes:

1. **API Server** — el guardian que valida y registra todo en etcd.
2. **kube-scheduler** — el asignador que decide donde vive cada Pod.
3. **kubelet** — el supervisor local que arranca y vigila los contenedores.
4. **kube-proxy** — el enrutador que hace funcionar los Services.
5. **Container Runtime** — el motor que materializa los contenedores.

Juntos, estos componentes implementan la promesa central de Kubernetes: declaras QUE quieres
(en YAML) y el sistema hace todo lo necesario para lograrlo y mantenerlo.

---

## Limpieza

```bash
./cleanup.sh
```

---

## Checklist de Conocimientos

Usa esta lista para verificar que entendiste los conceptos clave del lab:

- [ ] El API Server valida y persiste todos los recursos en etcd
- [ ] El Scheduler asigna Pods a nodos evaluando recursos y restricciones como nodeSelector
- [ ] kubelet ejecuta las health probes y reinicia contenedores que fallan
- [ ] kube-proxy implementa Services con reglas iptables/IPVS en cada nodo
- [ ] El container runtime (containerd/CRI-O) gestiona el ciclo de vida del contenedor via CRI
- [ ] Una NetworkPolicy requiere un CNI compatible (Calico, Cilium, etc.)
- [ ] La ClusterIP de un Service es una IP virtual estable que abstrae los Pods individuales
- [ ] CoreDNS permite usar nombres de Service en lugar de IPs numericas
- [ ] Los eventos de un Pod (`kubectl get events`) registran toda la historia de su ciclo de vida
- [ ] `RESTARTS: 0` en `kubectl get pods` confirma que kubelet esta satisfecho con el contenedor
