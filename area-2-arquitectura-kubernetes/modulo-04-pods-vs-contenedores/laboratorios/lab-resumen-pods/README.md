# Lab Resumen: Pods vs Contenedores

Revision guiada de 60 minutos sobre los conceptos clave de Pods multi-container,
disenada para ejecutarse en Minikube. Pensada para personas que recien empiezan
con Kubernetes y quieren entender como funcionan los Pods desde cero.

**Duracion:** 60 minutos | **Nivel:** Principiante/Intermedio | **Archivo:** `pods-lab.yaml`

Un solo YAML despliega un namespace aislado con Pods que demuestran los cuatro
patrones clave del modulo: multi-container con shared network, PID namespace
compartido, patron sidecar con emptyDir, e init containers.

---

## Conceptos Previos: Que es un Contenedor y un Pod

Antes de ejecutar cualquier comando, es importante entender los dos conceptos
centrales de este laboratorio.

### Que es un contenedor?

Imagina que tienes un programa (por ejemplo, un servidor web) y quieres
ejecutarlo en cualquier computadora sin importar el sistema operativo que tenga.
Un contenedor es como una **caja liviana y portatil** que empaqueta ese programa
junto con todo lo que necesita para funcionar: sus librerias, su configuracion,
sus archivos. La caja siempre se comporta igual, sin importar donde la abras.

Los contenedores son mas ligeros que las maquinas virtuales porque no incluyen
un sistema operativo completo; comparten el kernel del sistema operativo del
servidor donde corren.

**En Kubernetes se usan contenedores Docker** (y otros formatos compatibles).

### Que es un Pod?

Un Pod es la **unidad mas pequena que Kubernetes puede gestionar**. No gestionas
contenedores directamente; gestionas Pods que contienen contenedores.

Piensa en un Pod como un **sobre**: dentro puede haber uno o varios contenedores
que necesitan trabajar juntos. Kubernetes siempre crea, escala y elimina Pods
completos, nunca contenedores individuales por separado.

Lo que hace especial a un Pod es que **todos sus contenedores comparten**:
- La misma direccion IP (red)
- Los mismos volumenes de almacenamiento (si se configuran)
- El mismo ciclo de vida (nacen y mueren juntos)

### Por que poner multiples contenedores en un Pod?

La mayoria de los Pods tienen un solo contenedor. Pero a veces dos programas
necesitan trabajar tan estrechamente que no tiene sentido separarlos:

- Un servidor web y un programa que procesa sus logs en tiempo real
- Una aplicacion y un agente que envia sus metricas a un sistema de monitoreo
- Una aplicacion y un "portero" que inicializa su configuracion antes de que arranque

En esos casos, se ponen juntos en el mismo Pod para que puedan compartir archivos
y comunicarse sin pasar por la red externa.

---

## Conceptos Cubiertos

| Componente | Concepto demostrado |
|------------|---------------------|
| `multi-container-pod` | Comunicacion localhost entre contenedores (nginx:80 + httpd:8080) |
| `shared-pid-pod` | Visibilidad de procesos entre contenedores con `shareProcessNamespace: true` |
| `sidecar-pod` | Patron logging con volumen emptyDir compartido entre app y sidecar |
| `init-container-pod` | Ejecucion secuencial: init escribe configuracion, app la lee al arrancar |
| Red del Pod | IP unica compartida entre todos los contenedores del mismo Pod |

---

## Archivo del Lab

| Archivo | Descripcion |
|---------|-------------|
| `pods-lab.yaml` | YAML unico con todos los recursos: Namespace + 5 Pods |
| `cleanup.sh` | Elimina el namespace `lab-pods-test` y todos sus recursos |

---

## Paso 0: Preparar Minikube (2 min)

```bash
minikube start

# Verificar estado
minikube status
kubectl cluster-info
```

**Salida esperada:**

```
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

---

## Paso 1: Desplegar Todo (1 min)

```bash
kubectl apply -f pods-lab.yaml
```

**Salida esperada:**

```
namespace/lab-pods-test created
pod/multi-container-pod created
pod/shared-pid-pod created
pod/sidecar-pod created
pod/init-container-pod created
pod/test-pod created
```

Esperar a que todos los Pods esten listos (el init container tarda ~5s):

```bash
kubectl get pods -n lab-pods-test --watch
```

**Salida esperada (despues de ~30s):**

```
NAME                  READY   STATUS    RESTARTS   AGE
init-container-pod    1/1     Running   0          25s
multi-container-pod   2/2     Running   0          25s
shared-pid-pod        2/2     Running   0          25s
sidecar-pod           2/2     Running   0          25s
test-pod              1/1     Running   0          25s
```

**Que significa la columna READY?**

El valor `2/2` significa "2 de 2 contenedores estan listos". Si un Pod tiene
dos contenedores y ambos estan corriendo correctamente, veras `2/2`. Si solo
uno de los dos esta listo, veras `1/2`. Un Pod con un solo contenedor muestra
`1/1`. Kubernetes no considera un Pod "listo" hasta que TODOS sus contenedores
esten en estado Ready.

---

## Paso 2: Multi-container Pod y Shared Network (3 min)

**Concepto antes de empezar:**

Imagina que un Pod es como un apartamento. Los contenedores son las personas
que viven ahi. Aunque cada persona hace cosas distintas, comparten la misma
direccion postal (la IP del Pod), la misma conexion a internet (la red), y
pueden hablar entre ellas sin salir a la calle (via localhost).

Sin embargo, igual que en un apartamento cada persona tiene su propia
habitacion, cada contenedor escucha en un puerto diferente. No pueden compartir
el mismo puerto, igual que dos personas no pueden usar la misma habitacion al
mismo tiempo.

En este paso vamos a verificar que dos contenedores dentro del mismo Pod
(nginx en el puerto 80, httpd/Apache en el puerto 8080) pueden llamarse
entre si usando simplemente `localhost`, como si estuvieran en la misma maquina.

```bash
# Ver los dos contenedores del Pod
kubectl get pod multi-container-pod -n lab-pods-test -o jsonpath='{.spec.containers[*].name}'
```

**Salida esperada:** `nginx httpd`

```bash
# Desde nginx, llamar a httpd via localhost:8080
kubectl exec multi-container-pod -n lab-pods-test -c nginx -- wget -qO- http://localhost:8080
```

**Salida esperada:** Respuesta HTML de Apache httpd (`<html><body><h1>It works!</h1></body></html>`)

```bash
# Desde httpd, llamar a nginx via localhost:80
kubectl exec multi-container-pod -n lab-pods-test -c httpd -- wget -qO- http://localhost:80
```

**Salida esperada:** Pagina de bienvenida de nginx

```bash
# Verificar que ambos comparten la misma IP
kubectl get pod multi-container-pod -n lab-pods-test -o wide
```

**Pregunta:** Por que pueden comunicarse via localhost? Los dos contenedores comparten el
network namespace del Pod: misma interfaz de red, misma IP, mismo stack TCP/IP.

**Que aprendimos:** Dos contenedores en el mismo Pod comparten la red como si
fueran dos programas corriendo en la misma maquina. Pueden llamarse entre si
con `localhost` sin necesitar una IP externa ni un Service de Kubernetes.

---

## Paso 3: Shared PID Namespace (2 min)

**Concepto antes de empezar:**

Un "proceso" es un programa que esta corriendo en este momento. Cuando abres
un navegador, eso es un proceso. Cuando nginx sirve paginas web, eso es otro
proceso. Cada proceso tiene un numero de identificacion unico llamado PID
(Process ID).

Normalmente, cada contenedor vive en su propio espacio de procesos aislado:
un contenedor no puede ver los procesos de otro contenedor, aunque esten en
el mismo Pod. Esto es una medida de seguridad y separacion.

Pero a veces es util que un contenedor pueda inspeccionar los procesos de su
vecino. Por ejemplo, un contenedor de debug podria necesitar ver si nginx esta
realmente corriendo. Para eso existe `shareProcessNamespace: true`: le dice a
Kubernetes que todos los contenedores del Pod compartan el mismo espacio de
PIDs, pudiendo verse mutuamente.

```bash
# Desde el contenedor "inspector", ver procesos de nginx
kubectl exec shared-pid-pod -n lab-pods-test -c inspector -- ps aux
```

**Salida esperada (incluye procesos de ambos contenedores):**

```
PID   USER     TIME  COMMAND
    1 root      0:00 /pause
    6 root      0:00 nginx: master process nginx -g daemon off;
   34 101       0:00 nginx: worker process
   35 root      0:00 sh -c sleep 3600
   42 root      0:00 sleep 3600
   43 root      0:00 ps aux
```

**Observacion:** Sin `shareProcessNamespace: true`, el inspector solo veria sus propios procesos.
Con esta opcion, todos los contenedores del Pod comparten el mismo espacio de PIDs.

**Que aprendimos:** Con `shareProcessNamespace: true` un contenedor puede ver
los procesos de todos sus vecinos en el mismo Pod. Esto es util para depuracion
y monitoreo, pero debe usarse con cuidado porque reduce el aislamiento.

---

## Paso 4: Sidecar Pattern con emptyDir (3 min)

**Concepto antes de empezar:**

El patron sidecar (literalmente "sidecar" como la cabina lateral de una
motocicleta con sidecar) describe una arquitectura donde un contenedor
principal hace el trabajo central de la aplicacion, y un segundo contenedor
viaja "al costado" agregando funcionalidad extra sin modificar el primero.

Igual que en una motocicleta con sidecar: la moto conduce sola perfectamente,
pero el sidecar agrega capacidad de transporte extra sin cambiar el motor ni
el diseno de la moto.

Ejemplos comunes del patron sidecar:
- La app principal escribe logs en un archivo. El sidecar los lee y los envia
  a un sistema centralizado (como Elasticsearch o Splunk).
- La app expone metricas en formato propio. El sidecar las convierte al
  formato Prometheus.
- La app no tiene SSL. El sidecar actua como proxy y agrega cifrado.

En este paso, nginx escribe sus logs de acceso en un volumen compartido
(`emptyDir`). El sidecar `log-reader` lee esos mismos logs desde el mismo
volumen. El volumen `emptyDir` es como un directorio temporal que existe
mientras el Pod vive y es accesible por todos sus contenedores.

```bash
# Generar trafico en nginx para producir logs
kubectl exec sidecar-pod -n lab-pods-test -c nginx -- wget -qO- http://localhost:80 > /dev/null

# Ver los logs que captura el sidecar log-reader
kubectl logs sidecar-pod -n lab-pods-test -c log-reader
```

**Salida esperada:**

```
172.17.0.1 - - [01/Mar/2026:10:00:00 +0000] "GET / HTTP/1.1" 200 615 "-" "Wget" "-"
```

```bash
# Verificar que el volumen emptyDir es compartido
kubectl exec sidecar-pod -n lab-pods-test -c nginx -- ls /var/log/nginx/
kubectl exec sidecar-pod -n lab-pods-test -c log-reader -- ls /logs/
```

**Salida esperada (mismo contenido en ambas rutas):** `access.log  error.log`

**Patron sidecar:** nginx escribe en `/var/log/nginx`, el sidecar lee de `/logs`. Mismo
volumen `emptyDir`, montado en rutas distintas por cada contenedor.

**Que aprendimos:** El patron sidecar permite agregar capacidades (logging,
monitoreo, proxying) a una aplicacion sin tocar su codigo. El volumen `emptyDir`
actua como el canal de comunicacion entre los contenedores del Pod.

---

## Paso 5: Init Container (3 min)

**Concepto antes de empezar:**

Un init container es como un portero que prepara una sala de reuniones antes
de que lleguen los participantes. El portero entra primero, acomoda las sillas,
pone agua en la mesa, verifica que el proyector funcione. Solo cuando termina
y sale, los participantes pueden entrar.

En Kubernetes, los init containers son contenedores especiales que corren
ANTES de los contenedores principales de un Pod. Se usan para:

- Descargar archivos de configuracion antes de que la app arranque
- Esperar a que una base de datos este disponible antes de iniciar el backend
- Preparar permisos en un volumen antes de que la app lo use
- Verificar que servicios externos esten listos

La regla es estricta: el contenedor principal NO arranca hasta que TODOS los
init containers terminen exitosamente (con exit code 0). Si un init container
falla, Kubernetes lo reintenta hasta que funcione o hasta que se agote el
tiempo de espera.

```bash
# Verificar que el init container ya ejecuto y termino
kubectl describe pod init-container-pod -n lab-pods-test | grep -A 5 "Init Containers:"
```

**Salida esperada:**

```
Init Containers:
  setup:
    ...
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
```

```bash
# Ver el archivo de configuracion creado por el init container
kubectl exec init-container-pod -n lab-pods-test -c app -- cat /config/config.env
```

**Salida esperada:**

```
CONFIG_READY=true
INITIALIZED_AT=Sun Mar  1 10:00:05 UTC 2026
```

```bash
# Ver los logs del contenedor app (lee la config generada por init)
kubectl logs init-container-pod -n lab-pods-test -c app | head -5
```

**Salida esperada:**

```
App: leyendo configuracion generada por init container...
CONFIG_READY=true
INITIALIZED_AT=Sun Mar  1 10:00:05 UTC 2026
App: iniciando servicio principal...
```

**Concepto clave:** El contenedor `app` no arranca hasta que `setup` termina con exit code 0.
Los init containers se ejecutan uno por uno, en orden de definicion, antes de los contenedores principales.

**Que aprendimos:** Los init containers garantizan que la aplicacion principal
siempre arranca con su entorno ya preparado. Son la solucion correcta cuando
necesitas precondiciones cumplidas antes del inicio de la app.

---

## Paso 6: Verificacion con test-pod (1 min)

```bash
# Verificar que todos los Pods tienen IP unica en el namespace
kubectl get pods -n lab-pods-test -o wide
```

**Salida esperada:**

```
NAME                  READY   STATUS    IP           NODE
init-container-pod    1/1     Running   10.244.x.x   minikube
multi-container-pod   2/2     Running   10.244.x.x   minikube
shared-pid-pod        2/2     Running   10.244.x.x   minikube
sidecar-pod           2/2     Running   10.244.x.x   minikube
test-pod              1/1     Running   10.244.x.x   minikube
```

```bash
# Desde test-pod, verificar conectividad hacia multi-container-pod
MULTI_IP=$(kubectl get pod multi-container-pod -n lab-pods-test -o jsonpath='{.status.podIP}')
kubectl exec test-pod -n lab-pods-test -- wget -qO- http://$MULTI_IP:80 | head -3
kubectl exec test-pod -n lab-pods-test -- wget -qO- http://$MULTI_IP:8080 | head -3
```

**Salida esperada:** Respuesta HTML de nginx (puerto 80) y de httpd (puerto 8080) de `multi-container-pod`.

---

## Paso 7: Limpiar (1 min)

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete namespace lab-pods-test
kubectl config set-context --current --namespace=default
```

---

## Checklist de Conocimientos

Marca cada concepto que puedas explicar con tus propias palabras:

- [ ] Un Pod tiene **una sola IP**, aunque tenga multiples contenedores
- [ ] Los contenedores dentro de un Pod se comunican via **localhost**
- [ ] Cada contenedor en el Pod usa un **puerto unico** (no pueden repetirse)
- [ ] `shareProcessNamespace: true` permite ver procesos de otros contenedores del mismo Pod
- [ ] Un volumen `emptyDir` existe mientras el Pod vive y es compartido por todos sus contenedores
- [ ] Los init containers se ejecutan en **orden estricto** antes que los contenedores principales
- [ ] El contenedor principal no arranca hasta que **todos** los init containers terminen con exit 0
- [ ] El patron **sidecar** agrega funcionalidad (logging, proxy, monitoring) sin modificar la app principal

---

## Relevancia CKAD/CKA

Este laboratorio cubre los siguientes temas de examen:

| Tema | Examen | Frecuencia |
|------|--------|------------|
| Pods multi-container (sidecar, init) | CKAD | Alta |
| `shareProcessNamespace` | CKAD / CKA | Media |
| emptyDir como volumen temporal | CKAD | Alta |
| Init containers y dependencias | CKAD | Alta |
| Troubleshooting de Pods | CKA | Alta |

**Comandos clave para el examen:**

```bash
# Ver contenedores de un Pod
kubectl get pod <nombre> -o jsonpath='{.spec.containers[*].name}'

# Ejecutar en un contenedor especifico
kubectl exec <pod> -c <contenedor> -- <comando>

# Ver logs de un contenedor especifico
kubectl logs <pod> -c <contenedor>

# Ver estado de init containers
kubectl describe pod <nombre> | grep -A 5 "Init Containers:"
```
