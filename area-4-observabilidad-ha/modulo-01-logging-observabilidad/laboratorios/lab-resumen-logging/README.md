# Lab Resumen: Logging en Kubernetes

**Duracion:** 60 minutos | **Nivel:** Principiante | **Archivo:** `logging-lab.yaml`

Un solo YAML despliega un entorno completo de logging: una webapp nginx, una API con logs JSON estructurados, un generador de logs por nivel (INFO/WARN/ERROR), y un DaemonSet que simula un colector de logs como Fluentd. Todo en el namespace `lab-logging`.

---

## Conceptos Previos: Que son los Logs y Por Que Importan

### La analogia de las camaras de seguridad

Imagina un edificio de oficinas sin camaras de seguridad. Un dia aparece una ventana rota. No tienes forma de saber:
- A que hora exactamente ocurrio
- Quien estaba en esa zona
- Si fue un accidente o algo intencional
- Si paso algo antes que lo explique

Con camaras instaladas, puedes ir a la grabacion del momento exacto y ver todo lo que ocurrio — incluso unos minutos antes, para entender el contexto.

Los logs en Kubernetes funcionan exactamente igual. Sin logs, cuando un usuario reporta un error en tu aplicacion, no tienes respuestas para:
- Que Pod especifico proceso esa request
- Cual fue el mensaje de error exacto
- A que hora ocurrio
- Si hubo advertencias previas que lo anunciaban

Con logging correctamente configurado, puedes buscar el evento, ver el contexto completo y entender exactamente que paso.

### Que es un log

Un **log** es un registro escrito de un evento que ocurrio en un momento especifico dentro de un programa. Cada linea de log tipicamente contiene:

```
[NIVEL]  [TIMESTAMP]              [COMPONENTE]  [MENSAJE]
 INFO    2024-03-15T10:30:01Z     user-api      Request procesada: GET /users/42 → 200 OK
 ERROR   2024-03-15T10:30:05Z     user-api      Timeout conectando a base de datos (30s)
 WARN    2024-03-15T10:30:06Z     user-api      Reintentando conexion (intento 2 de 3)
```

Los programas escriben logs continuamente mientras se ejecutan. Sin un sistema para capturarlos y almacenarlos, esos registros se pierden cuando el proceso termina.

### stdout y stderr: los dos flujos de salida

Todos los programas en Linux tienen dos canales de salida predefinidos:

```
┌─────────────────────────────────────────────────────────────┐
│                      PROGRAMA / CONTENEDOR                  │
│                                                             │
│  ┌───────────────────────┐   ┌───────────────────────────┐  │
│  │       stdout          │   │         stderr            │  │
│  │ (standard output)     │   │  (standard error)         │  │
│  │                       │   │                           │  │
│  │  Salida normal del    │   │  Mensajes de error y      │  │
│  │  programa. Todo lo    │   │  advertencias. Separado   │  │
│  │  que "funciona bien"  │   │  para poder filtrarlos    │  │
│  │  va aqui.             │   │  independientemente.      │  │
│  │                       │   │                           │  │
│  │  kubectl logs pod     │   │  kubectl logs pod         │  │
│  │  (los ves aqui)       │   │  (tambien los ves aqui)   │  │
│  └───────────────────────┘   └───────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

En Kubernetes, la regla fundamental es: **los contenedores deben escribir sus logs a stdout y stderr**. Nunca a archivos internos del contenedor, porque esos archivos desaparecen cuando el contenedor muere.

Kubernetes captura automaticamente stdout y stderr de cada contenedor y los almacena en archivos JSON en el nodo host (`/var/log/containers/`). Desde ahi, `kubectl logs` los recupera para ti.

### Logs de aplicacion vs logs del sistema

Hay dos tipos de logs que encontraras en un cluster Kubernetes:

| Tipo | Quien los genera | Donde los ves | Para que sirven |
|------|-----------------|---------------|-----------------|
| Logs de aplicacion | Tu codigo (la app) | `kubectl logs <pod>` | Depurar errores de negocio, trazar requests, auditar acciones |
| Logs del sistema | Kubernetes, kubelet, etcd, containerd | En el nodo: `/var/log/syslog`, `journalctl` | Diagnosticar problemas del cluster, eventos de scheduling |

En este lab trabajamos principalmente con logs de aplicacion porque son los que controlas directamente y los que usas dia a dia para operar aplicaciones.

### Logging no estructurado vs estructurado

**Logging no estructurado (texto plano)**

Es el formato clasico. Legible para humanos pero dificil de procesar con maquinas:

```
2024-03-15 10:30:01 ERROR Connection timeout after 30s retrying 2/3
2024-03-15 10:30:05 INFO  User 42 logged in from IP 192.168.1.10
2024-03-15 10:30:09 WARN  Memory usage at 78% of limit
```

Problema: si quieres contar todos los errores del ultimo dia, necesitas parsear texto libre. Cada linea puede tener un formato ligeramente diferente segun quien escribio ese trozo de codigo.

**Logging estructurado (JSON)**

Cada log es un objeto con campos definidos. Facil de procesar, filtrar y buscar:

```json
{"timestamp":"2024-03-15T10:30:01Z","level":"ERROR","service":"api","user_id":42,"message":"Connection timeout","retry":2}
{"timestamp":"2024-03-15T10:30:05Z","level":"INFO","service":"api","user_id":42,"message":"User logged in","ip":"192.168.1.10"}
{"timestamp":"2024-03-15T10:30:09Z","level":"WARN","service":"api","memory_pct":78,"message":"Memory usage high"}
```

Ventaja: puedes hacer consultas como `WHERE level = "ERROR" AND service = "api" AND timestamp > hace_1_hora`. Los sistemas como Elasticsearch, Azure Log Analytics y Loki estan optimizados para este formato.

**Regla practica:** usa JSON para aplicaciones en produccion. Usa texto plano solo para scripts y herramientas simples de desarrollo.

### Flujo completo de logs en Kubernetes

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    FLUJO DE LOGS EN KUBERNETES                          │
│                                                                         │
│  Tu aplicacion                                                          │
│  ┌──────────────┐                                                       │
│  │  Container   │  stdout/stderr                                        │
│  │  (tu app)    │──────────────►  Container Runtime (containerd)        │
│  └──────────────┘               (captura y formatea como JSON)          │
│                                          │                              │
│                                          ▼                              │
│                              /var/log/containers/                       │
│                              <pod>_<ns>_<container>.log                 │
│                              (archivo en el NODO HOST)                  │
│                                          │                              │
│                              ┌───────────┴───────────┐                 │
│                              │                       │                 │
│                              ▼                       ▼                 │
│                      kubectl logs             DaemonSet collector       │
│                      (consulta             (Fluentd / Fluent Bit)       │
│                       directa)                       │                 │
│                                                      ▼                 │
│                                          Almacen centralizado           │
│                                          (Elasticsearch / Log Analytics │
│                                           / Loki / CloudWatch)         │
│                                                      │                 │
│                                                      ▼                 │
│                                          Dashboard + Alertas            │
│                                          (Kibana / Grafana / Azure)     │
└─────────────────────────────────────────────────────────────────────────┘
```

### kubectl logs vs soluciones completas

| Herramienta | Alcance | Retencion | Busqueda | Alertas | Caso de uso |
|-------------|---------|-----------|----------|---------|-------------|
| `kubectl logs` | 1 Pod a la vez | Solo logs actuales (hasta rotation) | Solo `grep` | No | Debugging rapido en desarrollo |
| Container Insights (AKS) | Todo el cluster | Configurable (30-90 dias) | KQL queries | Si | Produccion en Azure |
| EFK Stack (Elasticsearch + Fluentd + Kibana) | Todo el cluster | Configurable (indefinido) | Queries complejas | Si | Produccion on-premise o multi-cloud |
| Loki + Grafana | Todo el cluster | Configurable | LogQL queries | Si | Alternativa liviana a EFK |

En este lab usamos `kubectl logs` porque es la herramienta base que funciona en cualquier cluster sin instalar nada adicional. Las soluciones completas se construyen encima de este fundamento.

---

## Que despliega logging-lab.yaml

```
Namespace: lab-logging
│
├── ConfigMap: log-config
│     Configuracion de niveles y formato. Simula configuracion
│     centralizada que montaria un colector real como Fluent Bit.
│
├── Deployment: webapp (2 replicas)
│     Nginx con access logs a stdout. Cada request HTTP genera
│     una linea de log con metodo, URL, status y tiempo de respuesta.
│
├── Service: webapp
│     Expone webapp internamente para que test-tools genere trafico.
│
├── Deployment: api (1 replica)
│     Genera logs JSON estructurados a stdout. Mezcla realista:
│     70% INFO, 20% WARN, 10% ERROR. Los errores tambien van a stderr.
│
├── Pod: log-generator
│     Genera logs de texto plano con niveles INFO, WARN, ERROR
│     en ciclos de 5 segundos. Ideal para practicar grep y filtrado.
│
├── DaemonSet: log-collector
│     1 Pod por nodo (en Minikube = 1 Pod). Simula Fluentd/Fluent Bit:
│     imprime actividad de recoleccion y procesamiento de logs.
│
└── Pod: test-tools
      Genera trafico HTTP hacia webapp cada 20 segundos para
      producir access logs reales que puedas observar.
```

---

## Paso 0: Preparar Minikube

Antes de empezar, verifica que tienes Minikube funcionando y con recursos suficientes.

**Por que Minikube?** Minikube crea un cluster Kubernetes completo en tu maquina local dentro de una maquina virtual o contenedor. Es perfecto para aprender porque no requiere cloud ni infraestructura.

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

Si Minikube no esta corriendo, inicialo:

```bash
# Iniciar Minikube con recursos suficientes para el lab
minikube start --memory=2048 --cpus=2
```

**Salida esperada:**
```
* minikube v1.32.0 on Linux
* Using the docker driver based on existing profile
* Starting control plane node minikube
* Pulling base image ...
* Restarting existing docker container for "minikube" ...
* Done! kubectl is now configured to use "minikube" cluster
```

Verifica que kubectl apunta a Minikube:

```bash
kubectl cluster-info
```

**Salida esperada:**
```
Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

---

## Paso 1: Desplegar el Entorno Completo

Despliega todos los recursos de una sola vez con el YAML del lab:

```bash
kubectl apply -f logging-lab.yaml
```

**Salida esperada:**
```
namespace/lab-logging created
configmap/log-config created
deployment.apps/webapp created
service/webapp created
deployment.apps/api created
pod/log-generator created
daemonset.apps/log-collector created
pod/test-tools created
```

Kubernetes procesa el archivo en orden y crea cada recurso. El namespace se crea primero porque los demas recursos lo necesitan.

Espera a que todos los Pods esten listos:

```bash
kubectl get pods -n lab-logging --watch
```

**Salida esperada (puede tardar 60-90 segundos):**
```
NAME                         READY   STATUS              RESTARTS   AGE
api-7d9f8b6c5-xk2p9          0/1     ContainerCreating   0          5s
log-collector-n8qlv          0/1     ContainerCreating   0          5s
log-generator                0/1     ContainerCreating   0          5s
test-tools                   0/1     ContainerCreating   0          5s
webapp-5c4b9f7d8-jm3k1       0/1     ContainerCreating   0          5s
webapp-5c4b9f7d8-rp7qs       0/1     ContainerCreating   0          5s
```

Cuando todos muestren `Running`, presiona Ctrl+C para salir del modo watch.

```
NAME                         READY   STATUS    RESTARTS   AGE
api-7d9f8b6c5-xk2p9          1/1     Running   0          45s
log-collector-n8qlv          1/1     Running   0          45s
log-generator                1/1     Running   0          45s
test-tools                   1/1     Running   0          45s
webapp-5c4b9f7d8-jm3k1       1/1     Running   0          45s
webapp-5c4b9f7d8-rp7qs       1/1     Running   0          45s
```

Verifica el ConfigMap y el DaemonSet:

```bash
kubectl get all -n lab-logging
```

**Salida esperada:**
```
NAME                         READY   STATUS    RESTARTS   AGE
pod/api-7d9f8b6c5-xk2p9      1/1     Running   0          90s
pod/log-collector-n8qlv      1/1     Running   0          90s
pod/log-generator             1/1     Running   0          90s
pod/test-tools               1/1     Running   0          90s
pod/webapp-5c4b9f7d8-jm3k1   1/1     Running   0          90s
pod/webapp-5c4b9f7d8-rp7qs   1/1     Running   0          90s

NAME             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/webapp   ClusterIP   10.96.45.123   <none>        80/TCP    90s

NAME                          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/log-collector   1         1         1       1            1           <none>          90s

NAME                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/api      1/1     1            1           90s
deployment.apps/webapp   2/2     2            2           90s
```

> Que aprendimos? Con un solo `kubectl apply` Kubernetes leyo el YAML declarativo y creo 8 recursos distintos: 1 Namespace, 1 ConfigMap, 2 Deployments, 1 Service, 1 Pod independiente, 1 DaemonSet y 1 Pod de herramientas. Cada recurso empezo a funcionar tan pronto como sus dependencias estuvieron listas.

---

## Paso 2: Ver Logs Basicos con kubectl logs

El comando mas fundamental para observar lo que hace un contenedor es `kubectl logs`.

Primero obtengamos los nombres exactos de los Pods (los sufijos aleatorios cambian en cada despliegue):

```bash
kubectl get pods -n lab-logging
```

Ahora veamos los logs del generador de logs, que produce salida clara con niveles:

```bash
kubectl logs log-generator -n lab-logging
```

**Salida esperada:**
```
[INFO]  2024-03-15T10:30:01Z - Ciclo 1: Sistema funcionando correctamente
[INFO]  2024-03-15T10:30:01Z - Ciclo 1: Conexion a servicio verificada
---
[INFO]  2024-03-15T10:30:06Z - Ciclo 2: Sistema funcionando correctamente
[INFO]  2024-03-15T10:30:06Z - Ciclo 2: Conexion a servicio verificada
---
[INFO]  2024-03-15T10:30:11Z - Ciclo 3: Sistema funcionando correctamente
[INFO]  2024-03-15T10:30:11Z - Ciclo 3: Conexion a servicio verificada
[WARN]  2024-03-15T10:30:11Z - Ciclo 3: Uso de memoria supera 70% del limite
[WARN]  2024-03-15T10:30:11Z - Ciclo 3: Reintentando conexion (intento 2 de 3)
---
```

Ahora ve los logs del Pod del DaemonSet log-collector:

```bash
# Primero obtener el nombre del Pod del DaemonSet
kubectl get pods -n lab-logging -l app=log-collector

# Ver sus logs
kubectl logs -l app=log-collector -n lab-logging
```

**Salida esperada:**
```
[log-collector] Iniciando en nodo: minikube
[log-collector] Monitoreando /var/log/containers/ ...
[log-collector] Destino: Azure Log Analytics / Elasticsearch
---
[log-collector] 2024-03-15T10:30:15Z - Ciclo 1: Recopilando logs del nodo minikube
[log-collector] 2024-03-15T10:30:15Z - Ciclo 1: Procesados ~347 eventos
[log-collector] 2024-03-15T10:30:15Z - Ciclo 1: Enviados a almacen central. Cola: 0
```

Opciones utiles de `kubectl logs`:

```bash
# Ver solo las ultimas N lineas (util cuando hay muchos logs)
kubectl logs log-generator -n lab-logging --tail=10

# Ver logs con timestamp del sistema (cuando Kubernetes los recibio)
kubectl logs log-generator -n lab-logging --timestamps=true
```

**Salida esperada con timestamps:**
```
2024-03-15T10:30:01.234567890Z [INFO]  2024-03-15T10:30:01Z - Ciclo 1: Sistema funcionando correctamente
2024-03-15T10:30:01.234598123Z [INFO]  2024-03-15T10:30:01Z - Ciclo 1: Conexion a servicio verificada
```

Nota que hay DOS timestamps: el primero es cuando Kubernetes capturo el mensaje (del container runtime), el segundo es el que puso el programa mismo. Ambos son utiles pero por razones diferentes.

> Que aprendimos? `kubectl logs <pod>` es la ventana mas directa a lo que hace un contenedor. El flag `--tail` es esencial cuando el Pod lleva tiempo corriendo y hay miles de lineas de log. Los timestamps del sistema (`--timestamps`) ayudan a correlacionar eventos con lo que ocurria en el cluster en ese momento.

---

## Paso 3: Filtrar Logs por Nivel

En produccion, los logs generan miles de lineas por hora. Necesitas filtrar para encontrar rapidamente los eventos importantes.

La forma mas directa en Kubernetes es combinar `kubectl logs` con herramientas de texto como `grep`.

Primero mira todos los logs del generador para tener una idea del volumen:

```bash
kubectl logs log-generator -n lab-logging | wc -l
```

**Salida esperada (dependiendo del tiempo transcurrido):**
```
47
```

Ahora filtra solo los errores:

```bash
kubectl logs log-generator -n lab-logging | grep "\[ERROR\]"
```

**Salida esperada:**
```
[ERROR] 2024-03-15T10:30:36Z - Ciclo 7: No se pudo escribir en disco: Permission denied
[ERROR] 2024-03-15T10:30:36Z - Ciclo 7: Timeout esperando respuesta de la API externa
[ERROR] 2024-03-15T10:31:11Z - Ciclo 14: No se pudo escribir en disco: Permission denied
[ERROR] 2024-03-15T10:31:11Z - Ciclo 14: Timeout esperando respuesta de la API externa
```

Filtra solo las advertencias:

```bash
kubectl logs log-generator -n lab-logging | grep "\[WARN\]"
```

**Salida esperada:**
```
[WARN]  2024-03-15T10:30:11Z - Ciclo 3: Uso de memoria supera 70% del limite
[WARN]  2024-03-15T10:30:11Z - Ciclo 3: Reintentando conexion (intento 2 de 3)
[WARN]  2024-03-15T10:30:26Z - Ciclo 6: Uso de memoria supera 70% del limite
[WARN]  2024-03-15T10:30:26Z - Ciclo 6: Reintentando conexion (intento 2 de 3)
```

Contar cuantos errores hay en total:

```bash
kubectl logs log-generator -n lab-logging | grep -c "\[ERROR\]"
```

**Salida esperada:**
```
4
```

Filtrar todo lo que NO sea INFO (ver solo problemas):

```bash
kubectl logs log-generator -n lab-logging | grep -v "\[INFO\]" | grep -v "^---"
```

**Salida esperada:**
```
[WARN]  2024-03-15T10:30:11Z - Ciclo 3: Uso de memoria supera 70% del limite
[WARN]  2024-03-15T10:30:11Z - Ciclo 3: Reintentando conexion (intento 2 de 3)
[ERROR] 2024-03-15T10:30:36Z - Ciclo 7: No se pudo escribir en disco: Permission denied
[ERROR] 2024-03-15T10:30:36Z - Ciclo 7: Timeout esperando respuesta de la API externa
```

Buscar un mensaje especifico (util cuando ya sabes que buscas):

```bash
kubectl logs log-generator -n lab-logging | grep "Permission denied"
```

**Salida esperada:**
```
[ERROR] 2024-03-15T10:30:36Z - Ciclo 7: No se pudo escribir en disco: Permission denied
[ERROR] 2024-03-15T10:31:11Z - Ciclo 14: No se pudo escribir en disco: Permission denied
```

> Que aprendimos? El patron `kubectl logs <pod> | grep <patron>` es el workhorse del debugging diario. Puedes filtrar por nivel, por mensaje, por timestamp, por cualquier campo que aparezca en el log. En sistemas de logging centralizado como Elasticsearch, esta busqueda se hace con una query en la interfaz web en lugar de grep, pero el concepto es identico: filtrar el oceano de logs para ver solo lo que importa.

---

## Paso 4: Logs de Multiples Contenedores y Pods

Hasta ahora viste logs de un Pod a la vez. En produccion, necesitas ver logs de multiples instancias simultaneamente.

Ver logs de todos los Pods de un Deployment usando el label selector:

```bash
# El flag -l filtra por label. app=webapp selecciona ambas replicas del Deployment.
kubectl logs -l app=webapp -n lab-logging
```

**Salida esperada (intercalada de las 2 replicas):**
```
192.168.1.1 - - [15/Mar/2024:10:30:20 +0000] "GET /health HTTP/1.1" 200 3 "-" "curl/8.0.0" rt=0.000
192.168.1.1 - - [15/Mar/2024:10:30:21 +0000] "GET / HTTP/1.1" 200 142 "-" "curl/8.0.0" rt=0.001
192.168.1.1 - - [15/Mar/2024:10:30:22 +0000] "GET /no-existe HTTP/1.1" 404 153 "-" "curl/8.0.0" rt=0.000
192.168.1.1 - - [15/Mar/2024:10:30:40 +0000] "GET /health HTTP/1.1" 200 3 "-" "curl/8.0.0" rt=0.000
```

Para ver de que Pod viene cada linea, agrega `--prefix`:

```bash
kubectl logs -l app=webapp -n lab-logging --prefix=true --tail=5
```

**Salida esperada:**
```
[pod/webapp-5c4b9f7d8-jm3k1/nginx] 192.168.1.1 - - [15/Mar/2024:10:30:40 +0000] "GET /health HTTP/1.1" 200 3 "-" "curl/8.0.0" rt=0.000
[pod/webapp-5c4b9f7d8-rp7qs/nginx] 192.168.1.1 - - [15/Mar/2024:10:30:40 +0000] "GET /health HTTP/1.1" 200 3 "-" "curl/8.0.0" rt=0.000
[pod/webapp-5c4b9f7d8-jm3k1/nginx] 192.168.1.1 - - [15/Mar/2024:10:30:41 +0000] "GET / HTTP/1.1" 200 142 "-" "curl/8.0.0" rt=0.001
```

Con `--prefix` puedes ver exactamente cual replica proceso cada request. Esto es critico cuando un usuario reporta un error intermitente — puedes identificar si siempre viene del mismo Pod (problema en esa instancia) o se distribuye entre todos (problema global).

Ver los access logs de la webapp para observar el trafico que genera test-tools:

```bash
# Ver access logs con el formato personalizado
kubectl logs -l app=webapp -n lab-logging --tail=15
```

**Salida esperada:**
```
192.168.1.1 - - [15/Mar/2024:10:30:20 +0000] "GET /health HTTP/1.1" 200 3 "-" "curl/8.0.0" rt=0.000
192.168.1.1 - - [15/Mar/2024:10:30:21 +0000] "GET / HTTP/1.1" 200 142 "-" "curl/8.0.0" rt=0.001
192.168.1.1 - - [15/Mar/2024:10:30:22 +0000] "GET /no-existe HTTP/1.1" 404 153 "-" "curl/8.0.0" rt=0.000
```

Nota el `404` en la tercera linea. Es el request a `/no-existe` que genera test-tools intencionalmente para producir un error en los access logs. En nginx, los 404 van a `error.log` (stderr), pero los access logs (stdout) registran todas las requests incluyendo las fallidas.

> Que aprendimos? El flag `-l <label-selector>` es una de las caracteristicas mas poderosas de `kubectl logs` porque refleja la naturaleza de Kubernetes: los Pods son intercambiables dentro de un Deployment. En lugar de buscar por nombre (que cambia), filtras por el label que siempre es consistente. El flag `--prefix` convierte una vista mezclada en una vista rastreable por replica.

---

## Paso 5: Logs en Tiempo Real con -f (Follow)

En lugar de ver un snapshot estatico de los logs pasados, puedes seguirlos en tiempo real exactamente como hace `tail -f` en Linux.

Abre una nueva terminal y ejecuta:

```bash
# -f hace que el comando no termine: espera nuevas lineas y las muestra
kubectl logs -f log-generator -n lab-logging
```

**Salida esperada (continua):**
```
[INFO]  2024-03-15T10:35:01Z - Ciclo 42: Sistema funcionando correctamente
[INFO]  2024-03-15T10:35:01Z - Ciclo 42: Conexion a servicio verificada
---
[INFO]  2024-03-15T10:35:06Z - Ciclo 43: Sistema funcionando correctamente
...
```

Las nuevas lineas aparecen en tiempo real cada 5 segundos. Presiona Ctrl+C para detener.

Puedes combinar `-f` con `--since` para ver logs recientes en tiempo real:

```bash
# Solo logs de los ultimos 2 minutos, luego seguir en tiempo real
kubectl logs -f log-generator -n lab-logging --since=2m
```

Tambien puedes seguir multiples Pods simultaneamente:

```bash
# Seguir todas las replicas de webapp en tiempo real
kubectl logs -f -l app=webapp -n lab-logging --prefix=true
```

**Salida esperada (nueva linea cada ~20 segundos cuando test-tools genera trafico):**
```
[pod/webapp-5c4b9f7d8-jm3k1/nginx] 192.168.1.1 - - [15/Mar/2024:10:35:20 +0000] "GET /health HTTP/1.1" 200 3
[pod/webapp-5c4b9f7d8-rp7qs/nginx] 192.168.1.1 - - [15/Mar/2024:10:35:21 +0000] "GET / HTTP/1.1" 200 142
```

El caso de uso mas comun de `-f` en produccion es durante un despliegue: ejecutas `kubectl logs -f <pod-nuevo>` y observas si la aplicacion arranca correctamente o aparecen errores en los primeros segundos.

Presiona Ctrl+C cuando termines de observar.

> Que aprendimos? El flag `-f` convierte `kubectl logs` de una herramienta de investigacion historica en una herramienta de monitoreo en tiempo real. Es esencial durante deployments, actualizaciones de configuracion y cuando un usuario reporta un problema activo. La combinacion `-f --since=Xm` es particularmente util porque te muestra contexto reciente y luego te mantiene al dia.

---

## Paso 6: Inspeccion del ConfigMap y Rotacion de Logs

Kubernetes usa el container runtime (containerd) para rotar los logs de los contenedores automaticamente. Los archivos se almacenan en el nodo host y tienen un limite de tamano y de archivos historicos.

Primero, examina el ConfigMap que centraliza la configuracion de logging:

```bash
kubectl get configmap log-config -n lab-logging -o yaml
```

**Salida esperada:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: log-config
  namespace: lab-logging
data:
  LOG_FORMAT: json
  LOG_INTERVAL_SECONDS: "5"
  LOG_LEVEL: INFO
  fluentd.conf: |
    <source>
      @type tail
      path /var/log/containers/*.log
      tag kubernetes.*
      ...
```

El ConfigMap tiene dos tipos de datos:
- Pares clave-valor simples (`LOG_LEVEL`, `LOG_FORMAT`) que se inyectan como variables de entorno
- Un archivo de configuracion completo (`fluentd.conf`) que se montaria como volumen

Ahora verifica los limites de logging que Kubernetes aplica por defecto. En produccion se configuran en el kubelet:

```bash
# Ver la configuracion del nodo (incluye log rotation settings)
kubectl describe node minikube | grep -A5 "Capacity"
```

**Salida esperada:**
```
Capacity:
  cpu:                2
  ephemeral-storage:  20134592Ki
  hugepages-1Gi:      0
  hugepages-2Mi:      0
  memory:             4096000Ki
  pods:               110
```

Por defecto, el container runtime rota logs cuando alcanzan 10MB y conserva los ultimos 5 archivos rotatados. Para ver cuanto log ha generado un contenedor:

```bash
# Contar lineas de log de cada Pod
kubectl logs log-generator -n lab-logging | wc -l
kubectl logs -l app=webapp -n lab-logging | wc -l
kubectl logs -l app=api -n lab-logging | wc -l
```

**Salida esperada (numeros aproximados):**
```
87
34
23
```

> Que aprendimos? El ConfigMap es el mecanismo de Kubernetes para separar configuracion de codigo. En logging, esto significa que puedes cambiar el nivel de log (de INFO a DEBUG) sin tocar la imagen del contenedor — solo actualizas el ConfigMap y reinicias el Pod. La rotacion automatica de logs es gestionada por el container runtime, no por tu aplicacion: es parte de por que los contenedores deben escribir a stdout/stderr en lugar de archivos.

---

## Paso 7: Logging Estructurado (JSON)

Los logs JSON del Deployment `api` son el formato recomendado para produccion. Veamos como trabajar con ellos.

Ver los logs JSON del api:

```bash
kubectl logs -l app=api -n lab-logging --tail=10
```

**Salida esperada:**
```
{"timestamp":"2024-03-15T10:35:01Z","level":"INFO","service":"api","pod":"api-7d9f8b6c5-xk2p9","request_id":45,"message":"Request procesada correctamente","http_status":200}
{"timestamp":"2024-03-15T10:35:09Z","level":"INFO","service":"api","pod":"api-7d9f8b6c5-xk2p9","request_id":46,"message":"Request procesada correctamente","http_status":200}
{"timestamp":"2024-03-15T10:35:17Z","level":"WARN","service":"api","pod":"api-7d9f8b6c5-xk2p9","request_id":47,"message":"Tiempo de respuesta alto detectado","http_status":200}
{"timestamp":"2024-03-15T10:35:25Z","level":"ERROR","service":"api","pod":"api-7d9f8b6c5-xk2p9","request_id":48,"message":"Fallo al conectar con base de datos","http_status":500}
```

Con texto plano y grep solo puedes filtrar lineas completas. Con JSON puedes extraer campos especificos. Si tienes `jq` instalado (herramienta para procesar JSON):

```bash
# Extraer solo timestamp, nivel y mensaje (quitar el ruido)
kubectl logs -l app=api -n lab-logging | jq -r '. | "\(.timestamp) [\(.level)] \(.message)"'
```

**Salida esperada:**
```
2024-03-15T10:35:01Z [INFO] Request procesada correctamente
2024-03-15T10:35:09Z [INFO] Request procesada correctamente
2024-03-15T10:35:17Z [WARN] Tiempo de respuesta alto detectado
2024-03-15T10:35:25Z [ERROR] Fallo al conectar con base de datos
```

Filtrar solo los errores usando jq:

```bash
kubectl logs -l app=api -n lab-logging | jq 'select(.level == "ERROR")'
```

**Salida esperada:**
```json
{
  "timestamp": "2024-03-15T10:35:25Z",
  "level": "ERROR",
  "service": "api",
  "pod": "api-7d9f8b6c5-xk2p9",
  "request_id": 48,
  "message": "Fallo al conectar con base de datos",
  "http_status": 500
}
```

Contar errores por nivel:

```bash
kubectl logs -l app=api -n lab-logging | jq -r '.level' | sort | uniq -c | sort -rn
```

**Salida esperada:**
```
     12 INFO
      4 WARN
      2 ERROR
```

Si no tienes jq, puedes usar grep con JSON:

```bash
# Filtrar errores con grep (funciona pero menos preciso)
kubectl logs -l app=api -n lab-logging | grep '"level":"ERROR"'
```

Ver la diferencia entre stdout y stderr en el Pod api. Los errores van a ambos:

```bash
# Ver solo stderr (donde van los mensajes de ERROR del api)
# Nota: kubectl logs mezcla stdout y stderr por defecto
# En produccion, el DaemonSet colector puede tratarlos por separado
kubectl logs -l app=api -n lab-logging | grep "^\[ERROR\]"
```

**Salida esperada:**
```
[ERROR] Fallo al conectar con base de datos - request_id=48 status=500
```

> Que aprendimos? El logging estructurado en JSON transforma los logs de texto ilegible para maquinas a datos consultables. La diferencia entre `grep "ERROR"` y `jq 'select(.level == "ERROR")'` puede parecer pequena aqui, pero en produccion con millones de lineas de log y campos como `user_id`, `transaction_id`, `latency_ms`, la capacidad de consultar por campo especifico es lo que hace posible el debugging rapido. Elasticsearch, Azure Log Analytics y Loki explotan exactamente esta estructura.

---

## Resumen Visual del Entorno del Lab

```
                    NAMESPACE: lab-logging
                                │
        ┌───────────────────────┼──────────────────────────┐
        │                       │                          │
        ▼                       ▼                          ▼
  ┌──────────────┐       ┌──────────────┐          ┌──────────────┐
  │   webapp     │       │     api      │          │ log-generator│
  │  (2 replicas)│       │  (1 replica) │          │  (1 pod)     │
  │              │       │              │          │              │
  │  nginx con   │       │  logs JSON   │          │  INFO/WARN/  │
  │  access logs │       │  INFO/WARN/  │          │  ERROR cada  │
  │  a stdout    │       │  ERROR a     │          │  5 segundos  │
  │              │       │  stdout      │          │              │
  └──────┬───────┘       └──────────────┘          └──────────────┘
         │                                                 │
         │  trafico HTTP                                   │
         ▼                                                 ▼
  ┌──────────────┐                               kubectl logs + grep
  │  test-tools  │
  │  (genera     │       ┌─────────────────────────────────────────┐
  │  requests    │       │           DaemonSet: log-collector       │
  │  cada 20s)   │       │   1 Pod por nodo (en Minikube = 1 Pod)  │
  └──────────────┘       │   Simula Fluentd recolectando todos     │
                         │   los logs del nodo                     │
                         └─────────────────────────────────────────┘
```

---

## Comandos de Referencia Rapida

```bash
# Ver logs de un Pod
kubectl logs <pod> -n lab-logging

# Ver las ultimas N lineas
kubectl logs <pod> -n lab-logging --tail=20

# Ver logs con timestamps del sistema
kubectl logs <pod> -n lab-logging --timestamps=true

# Seguir logs en tiempo real
kubectl logs -f <pod> -n lab-logging

# Ver logs de los ultimos X minutos/horas
kubectl logs <pod> -n lab-logging --since=5m
kubectl logs <pod> -n lab-logging --since=1h

# Ver logs de todos los Pods con un label
kubectl logs -l app=webapp -n lab-logging

# Ver logs de multiples Pods con prefijo del Pod
kubectl logs -l app=webapp -n lab-logging --prefix=true

# Filtrar por nivel con grep
kubectl logs <pod> -n lab-logging | grep "\[ERROR\]"

# Filtrar JSON con jq
kubectl logs -l app=api -n lab-logging | jq 'select(.level == "ERROR")'

# Ver logs del contenedor anterior (si el Pod se reinicio)
kubectl logs <pod> -n lab-logging --previous

# Ver eventos del namespace (complemento a logs)
kubectl get events -n lab-logging --sort-by='.lastTimestamp'
```

---

## Errores Comunes para Principiantes

**"No se muestran logs aunque el Pod esta Running"**

El Pod puede estar corriendo pero aun no haber generado ninguna salida. Verifica:

```bash
# Ver desde el inicio con --since al principio del tiempo
kubectl logs <pod> -n lab-logging --since=1h

# Ver eventos del Pod para saber que paso durante el arranque
kubectl describe pod <pod> -n lab-logging | grep -A20 Events
```

Si el Pod acaba de iniciar, espera 10-30 segundos a que genere los primeros logs.

**"Error: container X is not running"**

El contenedor especificado no existe o esta en CrashLoopBackOff:

```bash
# Ver el estado real del Pod
kubectl describe pod <pod> -n lab-logging

# Ver logs del contenedor anterior (antes del crash)
kubectl logs <pod> -n lab-logging --previous
```

**"No encuentro el Pod del DaemonSet"**

Los Pods de DaemonSet tienen nombres con sufijos del nodo, no aleatorios:

```bash
# Buscar Pods del DaemonSet por label
kubectl get pods -n lab-logging -l app=log-collector

# Ver el DaemonSet directamente
kubectl describe daemonset log-collector -n lab-logging
```

**"Los logs del api no son JSON valido"**

Puede que estes mezclando stdout (JSON) y stderr (texto plano). El api escribe ERROR tanto en formato JSON a stdout como en texto plano a stderr. Ambos aparecen en `kubectl logs`. Para separar:

```bash
# Filtrar solo las lineas que son JSON valido
kubectl logs -l app=api -n lab-logging | jq . 2>/dev/null
```

---

## Limpieza

Cuando termines el lab, elimina todos los recursos:

```bash
chmod +x cleanup.sh
./cleanup.sh
```

**Salida esperada:**
```
🧹 Iniciando limpieza del Lab Resumen Logging...

  ✓ namespace/lab-logging eliminado (todos los recursos incluidos)

Restaurando namespace por defecto...
  ✓ Contexto restaurado a namespace 'default'

🎉 Limpieza completada!
```

O manualmente con un solo comando:

```bash
kubectl delete namespace lab-logging
```

Cuando eliminas el namespace, Kubernetes elimina en cascada todos los recursos dentro de el: Pods, Deployments, Services, ConfigMaps, DaemonSets. Solo necesitas el comando de namespace.
