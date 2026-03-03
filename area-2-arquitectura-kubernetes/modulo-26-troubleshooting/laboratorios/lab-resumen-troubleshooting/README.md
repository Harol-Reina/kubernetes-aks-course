# Resumen Rapido: Troubleshooting Kubernetes

**Duracion:** 60 minutos | **Nivel:** Principiante-Intermedio | **Archivo:** `troubleshooting-lab.yaml`

Este laboratorio resume los conceptos clave del Modulo 26: Troubleshooting de clusters Kubernetes. Despliega recursos con errores intencionales para practicar diagnostico rapido de problemas comunes en aplicaciones, networking y probes.

---

## Indice

1. [Que es el Troubleshooting y por que importa](#que-es-el-troubleshooting)
2. [Conceptos Previos: los recursos que vas a ver](#conceptos-previos)
3. [Metodologia de Troubleshooting paso a paso](#metodologia-de-troubleshooting)
4. [Resumen Visual de Estados y Errores](#resumen-visual-de-estados-y-errores)
5. [Herramientas de Diagnostico](#herramientas-de-diagnostico)
6. [Ejercicio Practico (60 min)](#ejercicio-practico-60-min)
7. [Donde Buscar segun el Tipo de Problema](#donde-buscar-segun-el-tipo-de-problema)
8. [Preparacion CKA: Comandos Rapidos](#preparacion-cka-comandos-rapidos)

---

## Que es el Troubleshooting

### La analogia del detective

Imagina que eres un detective. Alguien llega a tu oficina y te dice "mi aplicacion no funciona". Tu trabajo es descubrir POR QUE no funciona y COMO arreglarlo, usando pistas y evidencia.

En Kubernetes, el troubleshooting (diagnostico de problemas) funciona exactamente igual:

- **El crimen**: la aplicacion no responde, o un Pod no arranca, o el trafico no llega.
- **Las pistas**: los logs (mensajes internos), los eventos (historial de lo que paso), el estado de los recursos.
- **Las herramientas**: `kubectl describe`, `kubectl logs`, `kubectl get events`.
- **La solucion**: corregir la configuracion incorrecta, la imagen equivocada, o el puerto mal puesto.

### Por que es una habilidad critica

En el mundo real, las aplicaciones en Kubernetes fallan. Puede ser porque:

- Un desarrollador subio una imagen con un tag que no existe.
- Un archivo de configuracion tiene un typo (error de escritura).
- Un Service esta apuntando a Pods equivocados por un label mal escrito.
- Un health check (probe) esta verificando una ruta que no existe.

Sin saber como diagnosticar estos problemas, un equipo puede perder horas o dias buscando el error. Con la metodologia correcta, el mismo problema se resuelve en minutos.

Esta habilidad es **obligatoria** en los examenes CKA y CKAD. Aproximadamente el 30% de las preguntas del CKA involucran troubleshooting de algun tipo.

---

## Conceptos Previos

Antes de hacer el laboratorio, asegurate de entender estos recursos basicos. Si ya los conoces, puedes saltar directamente a la seccion de metodologia.

### Pod

Un Pod es la unidad mas pequena de Kubernetes. Contiene uno o mas contenedores (aplicaciones). Piensalo como una "caja" donde vive tu aplicacion.

```
+---------------------------+
|          Pod              |
|  +---------------------+  |
|  |    Contenedor       |  |
|  |  (tu aplicacion)    |  |
|  +---------------------+  |
+---------------------------+
```

Un Pod puede estar en varios estados:

| Estado | Que significa |
|--------|---------------|
| `Pending` | Kubernetes acepto el Pod pero todavia no lo inicio (buscando un Node disponible) |
| `Running` | El Pod esta ejecutandose (pero puede que no este listo para recibir trafico) |
| `CrashLoopBackOff` | El contenedor arranco, fallo, y Kubernetes lo esta reiniciando en un ciclo |
| `ImagePullBackOff` | Kubernetes no puede descargar la imagen del contenedor |
| `Completed` | El Pod termino su tarea y salio exitosamente |

La columna `READY` en `kubectl get pods` muestra cuantos contenedores estan listos. `1/1` significa "1 de 1 listo". `0/1` significa "0 de 1 listos", es decir, el Pod existe pero no esta disponible para recibir trafico.

### Deployment

Un Deployment es un controlador que gestiona un conjunto de Pods. Le dices "quiero 3 replicas del Pod X", y el Deployment se asegura de que siempre haya exactamente 3 Pods ejecutandose, incluso si alguno falla.

```
Deployment
  └── ReplicaSet
        ├── Pod 1  (Running)
        ├── Pod 2  (Running)
        └── Pod 3  (Pending)  <- algo salio mal aqui
```

Cuando haces troubleshooting de un Deployment, normalmente terminas mirando los Pods que el Deployment creo, porque ahi estan los errores reales.

### Service

Un Service es como una "puerta de entrada" a tus Pods. Los Pods tienen IPs que cambian cuando se reinician. El Service tiene una IP fija y sabe a que Pods enviar el trafico usando **labels** (etiquetas).

```
Cliente --> Service (IP fija: 10.96.x.x)
               |
               +--> Pod A (label: app=backend)
               +--> Pod B (label: app=backend)
               +--> Pod C (label: app=backend)
```

El Service usa un **selector** para encontrar los Pods. Si el selector dice `app: backend` pero los Pods tienen la etiqueta `app: back-end` (con guion), el Service no encontrara ningun Pod. Eso se llama **label mismatch** y es uno de los errores mas comunes.

### Probes (Liveness y Readiness)

Las probes son verificaciones de salud automaticas que Kubernetes hace a tus Pods:

- **Liveness Probe**: "Sigue vivo el contenedor?" Si falla, Kubernetes mata y reinicia el contenedor.
- **Readiness Probe**: "Esta listo para recibir trafico?" Si falla, Kubernetes quita el Pod del Service hasta que este listo.

Una probe tipicamente hace una peticion HTTP a una ruta especifica del contenedor. Si la ruta no existe o el puerto esta mal, la probe falla y el Pod tiene problemas.

---

## Metodologia de Troubleshooting

### El enfoque de 4 pasos

Cada vez que algo falla en Kubernetes, sigue estos 4 pasos en orden. No te saltes pasos, porque cada uno te da informacion que necesitas para el siguiente.

```
PASO 1: IDENTIFICAR
   "Que recursos tienen problemas?"
   kubectl get pods/nodes/svc

        |
        v

PASO 2: DIAGNOSTICAR
   "Por que tienen problemas?"
   kubectl describe <recurso>
   kubectl logs <pod> [--previous]
   kubectl get events

        |
        v

PASO 3: CORREGIR
   "Como lo arreglo?"
   kubectl edit / kubectl patch / kubectl set image

        |
        v

PASO 4: VERIFICAR
   "Funciono el arreglo?"
   kubectl get pods (STATUS: Running, READY: 1/1)
```

### Paso 1: IDENTIFICAR - "Ver el panorama general"

El primer paso siempre es obtener una vision general. No empieces a mirar detalles sin saber primero que esta fallando.

```bash
# Ver todos los Pods en todos los namespaces, filtrando los que no estan Running
kubectl get pods -A | grep -v Running

# Ver el estado de los Nodes
kubectl get nodes

# Ver Services y sus endpoints
kubectl get svc,endpoints -n <namespace>
```

En la columna `STATUS` busca:
- Cualquier cosa que NO sea `Running` o `Completed` es sospechosa.
- En la columna `RESTARTS`, un numero alto (5, 10, 50) indica que el Pod esta fallando repetidamente.
- En la columna `READY`, un `0/1` indica que el Pod existe pero no esta disponible.

### Paso 2: DIAGNOSTICAR - "Leer las pistas"

Una vez que sabes cual recurso falla, necesitas saber por que. Tienes tres fuentes de informacion:

**Fuente 1: `kubectl describe`** - El archivo del caso

Este comando te da todo el detalle de un recurso: su configuracion, su historial, y los **Events** (eventos). Los eventos son el log de lo que le paso al recurso. SIEMPRE mira los eventos al final del output de `describe`.

```bash
kubectl describe pod <nombre-del-pod> -n <namespace>
```

Busca en la seccion `Events` mensajes como:
- `Failed to pull image`: la imagen no existe o el tag es incorrecto.
- `Back-off restarting failed container`: el contenedor fallo y Kubernetes lo intento reiniciar.
- `Liveness probe failed`: la prueba de salud fallo.
- `Insufficient cpu/memory`: no hay suficientes recursos en los Nodes.

**Fuente 2: `kubectl logs`** - El diario del contenedor

Los logs son los mensajes que escribe tu aplicacion. Si el contenedor arranco pero fallo, sus logs te diran exactamente que error tuvo.

```bash
# Logs actuales del contenedor
kubectl logs <pod> -n <namespace>

# Logs del intento ANTERIOR (si el contenedor ya se reinicio)
kubectl logs <pod> -n <namespace> --previous
```

El flag `--previous` es fundamental. Si el contenedor ya murio y se reinicio, los logs actuales son del nuevo intento. Los logs del intento anterior (donde ocurrio el error) solo se ven con `--previous`.

**Fuente 3: `kubectl get events`** - El historial del namespace

Los eventos del namespace muestran todo lo que paso en orden cronologico, de todos los recursos.

```bash
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

Esto es util cuando no sabes exactamente cual recurso fallo, porque ves todo en una sola vista.

### Paso 3: CORREGIR - "Resolver el caso"

Una vez que identificaste la causa raiz, hay varias formas de corregir el problema:

| Situacion | Comando de correccion |
|-----------|----------------------|
| Cambiar la imagen de un Deployment | `kubectl set image deployment/<nombre> <container>=<imagen>:<tag>` |
| Cambiar un campo de configuracion | `kubectl edit deployment/<nombre>` (abre un editor) |
| Cambiar un campo especifico | `kubectl patch deployment/<nombre> -p '<json>'` |
| Recrear un Pod con nueva config | `kubectl delete pod <nombre>` (si tiene controller, el Deployment recrea uno nuevo) |
| Corregir el selector de un Service | `kubectl patch svc <nombre> -p '<json>'` |

### Paso 4: VERIFICAR - "Confirmar que el caso esta cerrado"

Despues de aplicar la correccion, verifica que el problema se resolvio:

```bash
# El estado debe ser Running y READY 1/1
kubectl get pods -n <namespace>

# Los logs no deben mostrar errores
kubectl logs <pod> -n <namespace>

# Para Services, verificar que tienen endpoints
kubectl get endpoints -n <namespace>
```

---

## Resumen Visual de Estados y Errores

### Estados de Pod y sus causas tipicas

| Estado | Causa Tipica | Comando Diagnostico |
|--------|-------------|---------------------|
| `CrashLoopBackOff` | Comando/args incorrectos, config faltante | `kubectl logs <pod> --previous` |
| `ImagePullBackOff` | Tag de imagen inexistente o privada | `kubectl describe pod` ver Events |
| `OOMKilled` | Memory limits insuficientes (exit code 137) | `kubectl describe pod` ver Last State |
| `Pending` | Sin recursos disponibles, scheduler down, PVC Pending | `kubectl describe pod` ver Events |
| `Init:0/1` | Init container esperando dependencia | `kubectl logs <pod> -c <init-container>` |
| `Running 0/1` | Readiness probe fallando | `kubectl describe pod` ver Readiness |
| `CreateContainerConfigError` | ConfigMap o Secret referenciado no existe | `kubectl describe pod` ver Events |

### Errores de Networking

| Problema | Causa Tipica | Diagnostico |
|----------|-------------|-------------|
| Service sin Endpoints | Label mismatch entre Pod y Service selector | `kubectl get endpoints <svc>` |
| DNS no resuelve | CoreDNS Pods no estan Running | `kubectl get pods -n kube-system -l k8s-app=kube-dns` |
| Port mismatch | targetPort en Service no coincide con containerPort del Pod | Comparar `kubectl get svc -o yaml` vs `kubectl get pod -o yaml` |
| NetworkPolicy bloqueando | Policy deny-all sin reglas de permiso | `kubectl get networkpolicies` |

---

## Herramientas de Diagnostico

| Herramienta | Para que sirve | Ejemplo |
|-------------|----------------|---------|
| `kubectl describe` | Ver eventos, config detallada, historial de un recurso | `kubectl describe pod webapp-crash` |
| `kubectl logs` | Ver los mensajes que escribe el contenedor (stdout/stderr) | `kubectl logs <pod> --previous` |
| `kubectl get events` | Ver todos los eventos del namespace en orden | `kubectl get events --sort-by='.lastTimestamp'` |
| `kubectl exec` | Ejecutar un comando DENTRO del Pod (como SSH) | `kubectl exec <pod> -- nslookup kubernetes` |
| `kubectl top` | Ver cuanto CPU y memoria esta usando cada Pod | `kubectl top pods --sort-by=memory` |
| `journalctl` | Ver logs del kubelet y otros servicios del sistema | `sudo journalctl -u kubelet -n 100` |
| `crictl` | Debug del container runtime (capa mas baja que kubectl) | `sudo crictl ps -a`, `sudo crictl logs <id>` |

---

## Ejercicio Practico (60 min)

En este ejercicio vas a:
1. Desplegar recursos que tienen errores intencionales.
2. Diagnosticar cada error usando la metodologia de 4 pasos.
3. Aplicar las correcciones.
4. Verificar que todo quedo funcionando.

Los errores en este laboratorio son reales y tipicos de lo que encontraras en produccion y en el examen CKA.

### Paso 1: Desplegar Recursos con Errores (2 min)

Primero, aplica el archivo YAML que crea todos los recursos del laboratorio. Algunos de estos recursos tienen errores intencionales que tendras que diagnosticar y corregir.

```bash
# Aplicar todos los recursos (incluye errores intencionales)
kubectl apply -f troubleshooting-lab.yaml
```

Output esperado:

```
namespace/lab-troubleshooting-test created
deployment.apps/webapp-crash created
deployment.apps/api-broken created
deployment.apps/backend-ok created
service/backend-broken-svc created
service/backend-ok-svc created
pod/web-liveness-broken created
pod/web-readiness-broken created
pod/busybox-dns-test created
pod/curl-test created
```

Cada linea de "created" confirma que Kubernetes acepto el recurso. Pero "aceptado" no significa "funcionando correctamente". Algunos van a fallar inmediatamente.

```bash
# Verificar que el namespace se creo
kubectl get namespace lab-troubleshooting-test
```

Output esperado:

```
NAME                       STATUS   AGE
lab-troubleshooting-test   Active   10s
```

---

### Paso 2: Diagnosticar Application Issues (10 min)

#### Escenario A: CrashLoopBackOff

**Que deberia hacer este recurso cuando funciona correctamente:**
El Deployment `webapp-crash` deberia ejecutar un servidor nginx y mantenerlo corriendo. Deberias ver 1 Pod en estado `Running` con `READY: 1/1`.

**Que error fue introducido intencionalmente:**
El contenedor usa nginx pero le pasa un archivo de configuracion que no existe: `-c /etc/nginx/nonexistent.conf`. Nginx arranca, intenta cargar ese archivo, no lo encuentra, y muere. Kubernetes lo reinicia, y el ciclo se repite.

**Como diagnosticar (enfoque detective):**
Primero observa el estado general, luego profundiza en el Pod especifico.

```bash
# Ver estado de todos los Pods
kubectl get pods -n lab-troubleshooting-test
```

Output esperado (los tiempos y contadores de reinicios pueden variar):

```
NAME                            READY   STATUS             RESTARTS   AGE
webapp-crash-xxxxxxxxx-xxxxx    0/1     CrashLoopBackOff   3          45s
api-broken-xxxxxxxxx-xxxxx      0/1     ImagePullBackOff   0          45s
backend-ok-xxxxxxxxx-xxxxx      1/1     Running            0          45s
backend-ok-xxxxxxxxx-xxxxx      1/1     Running            0          45s
web-liveness-broken             1/1     Running            0          45s
web-readiness-broken            0/1     Running            0          45s
busybox-dns-test                1/1     Running            0          45s
curl-test                       1/1     Running            0          45s
```

Lo que debes observar:
- `webapp-crash`: Estado `CrashLoopBackOff` con `RESTARTS` aumentando. Significa que el contenedor falla y se reinicia repetidamente.
- `api-broken`: Estado `ImagePullBackOff`. Significa que Kubernetes no puede descargar la imagen.
- `web-readiness-broken`: `READY: 0/1`. El Pod existe pero no esta listo.

Ahora diagnostica el CrashLoopBackOff:

```bash
# Leer los logs del intento ANTERIOR (el intento actual puede no tener logs aun)
kubectl logs -n lab-troubleshooting-test -l scenario=crashloop --previous 2>/dev/null
```

Output esperado:

```
2024/01/15 10:23:01 [emerg] 1#1: open() "/etc/nginx/nonexistent.conf" failed (2: No such file or directory)
nginx: [emerg] open() "/etc/nginx/nonexistent.conf" failed (2: No such file or directory)
```

**Que nos dice esto:** nginx intento abrir el archivo `/etc/nginx/nonexistent.conf` y no lo encontro. Ese es el error raiz. La solucion es quitarle el flag `-c /etc/nginx/nonexistent.conf` al contenedor.

```bash
# Confirmar el error con describe (ver la seccion Events al final)
kubectl describe pod -n lab-troubleshooting-test -l scenario=crashloop | grep -A 10 "Events"
```

Output esperado en Events:

```
Events:
  Warning  BackOff    5s    kubelet  Back-off restarting failed container app in pod webapp-crash-xxx
```

#### Escenario B: ImagePullBackOff

**Que deberia hacer este recurso cuando funciona correctamente:**
El Deployment `api-broken` deberia ejecutar un contenedor nginx. Deberias ver 1 Pod en estado `Running`.

**Que error fue introducido intencionalmente:**
La imagen especificada es `nginx:nonexistent-tag-12345`. Ese tag no existe en el registry (DockerHub). Kubernetes intenta descargar la imagen, falla, espera un poco, lo intenta de nuevo, y sigue fallando indefinidamente.

**Como diagnosticar:**

```bash
# El describe muestra los Events con el error de pull
kubectl describe pod -n lab-troubleshooting-test -l scenario=imagepull | grep -A 15 "Events"
```

Output esperado en Events:

```
Events:
  Warning  Failed     10s   kubelet  Failed to pull image "nginx:nonexistent-tag-12345":
                                     rpc error: ... manifest unknown
  Warning  Failed     10s   kubelet  Error: ErrImagePull
  Warning  BackOff    5s    kubelet  Back-off pulling image "nginx:nonexistent-tag-12345"
```

**Que nos dice esto:** `manifest unknown` significa que el tag `nonexistent-tag-12345` no existe en el registry de nginx. La solucion es cambiar la imagen a una version valida como `nginx:1.21`.

**Que acabamos de aprender en el Paso 2:**
- `CrashLoopBackOff` significa que el contenedor arranca pero falla. Los logs con `--previous` te dicen el error exacto.
- `ImagePullBackOff` significa que la imagen no se puede descargar. El `describe` te muestra el mensaje del registry.
- Siempre mira los **Events** al final del output de `describe`. Son la pista mas importante.

---

### Paso 3: Diagnosticar Service sin Endpoints (10 min)

**Que deberia hacer este recurso cuando funciona correctamente:**
Un Service debe enrutar trafico a los Pods que coincidan con su selector. Cuando funciona correctamente, el comando `kubectl get endpoints` muestra las IPs de los Pods. Cuando esta roto, los Endpoints estan vacios.

**Que error fue introducido intencionalmente:**
El Service `backend-broken-svc` tiene un selector que dice `app: backend-wrong`, pero los Pods del Deployment `backend-ok` tienen el label `app: backend`. Esa diferencia de `backend` vs `backend-wrong` hace que el Service no encuentre ningun Pod.

**Como diagnosticar:**

```bash
# Ver todos los Services del namespace
kubectl get svc -n lab-troubleshooting-test
```

Output esperado:

```
NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
backend-broken-svc    ClusterIP   10.96.x.x       <none>        80/TCP    2m
backend-ok-svc        ClusterIP   10.96.x.x       <none>        80/TCP    2m
```

Los dos Services se ven identicos en esta vista. El problema no es visible aqui. Necesitas ver los Endpoints:

```bash
# Comparar endpoints: uno funciona, el otro no
kubectl get endpoints -n lab-troubleshooting-test backend-broken-svc
```

Output esperado:

```
NAME                  ENDPOINTS   AGE
backend-broken-svc    <none>      2m
```

`<none>` significa que no hay ningun Pod conectado a este Service. El trafico que llegue al Service no tiene a donde ir.

```bash
kubectl get endpoints -n lab-troubleshooting-test backend-ok-svc
```

Output esperado:

```
NAME             ENDPOINTS                       AGE
backend-ok-svc   10.244.0.5:80,10.244.0.6:80    2m
```

Este Service si tiene Pods. Ahora busca por que el primero no tiene:

```bash
# Ver el selector del Service roto
kubectl get svc -n lab-troubleshooting-test backend-broken-svc -o jsonpath='{.spec.selector}'
```

Output esperado:

```
{"app":"backend-wrong","tier":"api"}
```

```bash
# Ver los labels reales de los Pods
kubectl get pods -n lab-troubleshooting-test --show-labels | grep backend
```

Output esperado:

```
backend-ok-xxxxx   1/1   Running   0   3m   app=backend,tier=api,...
```

**Que nos dice esto:** El Service busca Pods con `app=backend-wrong`, pero los Pods tienen `app=backend`. La "s" de diferencia hace que el Service no encuentre ningun Pod.

**Que acabamos de aprender en el Paso 3:**
- Un Service sin Endpoints no puede enrutar trafico a ningun lugar.
- `kubectl get endpoints` es el primer comando a ejecutar cuando un Service no funciona.
- La causa mas comun es un **label mismatch**: el selector del Service no coincide con los labels de los Pods.
- Siempre compara el `spec.selector` del Service con los labels reales de los Pods.

---

### Paso 4: Diagnosticar Probes (10 min)

#### Escenario A: Liveness Probe fallida

**Que deberia hacer este recurso cuando funciona correctamente:**
El Pod `web-liveness-broken` ejecuta nginx. Una Liveness Probe verifica cada ciertos segundos que el servidor siga respondiendo. Si responde, el Pod sigue corriendo. Si no responde, Kubernetes mata y reinicia el contenedor.

**Que error fue introducido intencionalmente:**
La Liveness Probe hace una peticion HTTP a la ruta `/healthz`. Pero nginx por defecto no tiene esa ruta. Cuando Kubernetes verifica la ruta, nginx responde con un error 404 (no encontrado). La probe interpreta eso como un fallo y reinicia el contenedor.

**Como diagnosticar:**

```bash
# Ver Pods con problemas de liveness (RESTARTS debe estar aumentando)
kubectl get pods -n lab-troubleshooting-test -l scenario=probe-failure
```

Output esperado (el numero de RESTARTS aumenta cada ~30 segundos):

```
NAME                   READY   STATUS    RESTARTS   AGE
web-liveness-broken    1/1     Running   2          3m
```

Nota que el Pod muestra `Running` y `1/1 READY`, pero los RESTARTS siguen aumentando. Esto es porque la probe falla despues de que el contenedor arranca, y Kubernetes lo reinicia.

```bash
# Ver el detalle de la Liveness Probe configurada
kubectl describe pod -n lab-troubleshooting-test web-liveness-broken | grep -A 10 "Liveness"
```

Output esperado:

```
Liveness:   http-get http://:80/healthz delay=5s timeout=1s period=10s #success=1 #failure=2
```

```bash
# Ver los eventos para confirmar que la probe esta fallando
kubectl describe pod -n lab-troubleshooting-test web-liveness-broken | grep -A 10 "Events"
```

Output esperado en Events:

```
Warning  Unhealthy  5s    kubelet  Liveness probe failed: HTTP probe failed with statuscode: 404
Warning  Killing    5s    kubelet  Container nginx failed liveness probe, will be restarted
```

**Que nos dice esto:** La probe hace GET a `/healthz` y recibe un 404. Eso hace fallar la probe. La solucion es cambiar la ruta a `/` (que si existe en nginx por defecto) o crear la ruta `/healthz` en la aplicacion.

#### Escenario B: Readiness Probe fallida

**Que deberia hacer este recurso cuando funciona correctamente:**
La Readiness Probe determina si el Pod esta listo para recibir trafico. Cuando funciona, el Pod aparece como `1/1 READY` y es incluido en los Endpoints del Service.

**Que error fue introducido intencionalmente:**
La Readiness Probe intenta conectarse al puerto `8080`, pero nginx escucha en el puerto `80`. Kubernetes no puede conectarse al puerto 8080 porque nada esta escuchando ahi.

**Como diagnosticar:**

```bash
# Ver Pods con readiness fallida (READY debe ser 0/1)
kubectl get pods -n lab-troubleshooting-test -l scenario=not-ready
```

Output esperado:

```
NAME                    READY   STATUS    RESTARTS   AGE
web-readiness-broken    0/1     Running   0          4m
```

El Pod esta `Running` (el contenedor esta vivo), pero `READY: 0/1` significa que no esta listo para recibir trafico. Esto es diferente al Liveness: la Readiness no mata el contenedor, solo lo excluye del Service.

```bash
# Ver el detalle de la Readiness Probe
kubectl describe pod -n lab-troubleshooting-test web-readiness-broken | grep -A 10 "Readiness"
```

Output esperado:

```
Readiness:  http-get http://:8080/ready delay=5s timeout=1s period=5s #success=1 #failure=3
```

```bash
# Ver los eventos
kubectl describe pod -n lab-troubleshooting-test web-readiness-broken | grep -A 5 "Events"
```

Output esperado:

```
Warning  Unhealthy  5s    kubelet  Readiness probe failed: Get "http://10.x.x.x:8080/ready":
                                    dial tcp 10.x.x.x:8080: connect: connection refused
```

**Que nos dice esto:** `connection refused` en el puerto 8080 significa que nada esta escuchando en ese puerto. nginx escucha en el 80, no en el 8080. La solucion es cambiar el puerto de la Readiness Probe de `8080` a `80`.

**Que acabamos de aprender en el Paso 4:**
- **Liveness Probe**: Si falla, el contenedor se reinicia (RESTARTS aumenta).
- **Readiness Probe**: Si falla, el Pod se queda en `0/1 READY` y no recibe trafico, pero el contenedor NO se reinicia.
- El `describe` del Pod muestra exactamente que probe fallo y con que error.
- Los errores mas comunes son: ruta equivocada (`404 Not Found`) o puerto equivocado (`connection refused`).

---

### Paso 5: Aplicar Correcciones (10 min)

Ahora que diagnosticaste todos los problemas, aplica las correcciones una por una.

#### Fix 1: CrashLoopBackOff - Corregir el comando

El problema era que se paso un archivo de configuracion que no existe. La correccion quita esos argumentos incorrectos y usa el comando correcto de nginx.

```bash
kubectl patch deployment webapp-crash -n lab-troubleshooting-test \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","command":["nginx"],"args":["-g","daemon off;"]}]}}}}'
```

Output esperado:

```
deployment.apps/webapp-crash patched
```

Verifica que el Pod nuevo ya no tiene el error:

```bash
kubectl rollout status deployment/webapp-crash -n lab-troubleshooting-test
# Espera hasta que diga "successfully rolled out"

kubectl get pods -n lab-troubleshooting-test -l scenario=crashloop
# Debe mostrar Running 1/1 con RESTARTS en 0 o muy bajo
```

#### Fix 2: ImagePullBackOff - Corregir la imagen

El problema era un tag de imagen que no existe. La correccion cambia el tag a uno valido.

```bash
kubectl set image deployment/api-broken api=nginx:1.21 -n lab-troubleshooting-test
```

Output esperado:

```
deployment.apps/api-broken image updated
```

```bash
# Verificar que el Pod nuevo esta descargando la imagen correctamente
kubectl get pods -n lab-troubleshooting-test -l scenario=imagepull
# Debe pasar de ImagePullBackOff a ContainerCreating y luego Running
```

#### Fix 3: Service sin Endpoints - Corregir el selector

El problema era que el selector del Service tenia `backend-wrong` en lugar de `backend`. La correccion actualiza el selector para que coincida con los labels reales de los Pods.

```bash
kubectl patch svc backend-broken-svc -n lab-troubleshooting-test \
  -p '{"spec":{"selector":{"app":"backend","tier":"api"}}}'
```

Output esperado:

```
service/backend-broken-svc patched
```

```bash
# Verificar que ahora el Service tiene Endpoints
kubectl get endpoints -n lab-troubleshooting-test backend-broken-svc
# Debe mostrar las IPs de los Pods, ya no <none>
```

#### Fix 4: Liveness Probe - Eliminar el Pod mal configurado

Este Pod no tiene un Deployment que lo gestione, por lo que para "arreglarlo" en este laboratorio simplemente lo eliminamos. En un caso real, editarias el manifiesto para cambiar la ruta de `/healthz` a `/`.

```bash
kubectl delete pod web-liveness-broken -n lab-troubleshooting-test
```

Output esperado:

```
pod "web-liveness-broken" deleted
```

Nota: Como es un Pod suelto (sin Deployment), no se recrea automaticamente.

---

### Paso 6: Verificar DNS y Conectividad (8 min)

El Pod `busybox-dns-test` fue creado precisamente para probar que el DNS interno del cluster funciona correctamente. El DNS es un servicio critico: si no funciona, los Pods no pueden encontrarse entre si por nombre.

**Como funciona el DNS en Kubernetes:**
Cada Service tiene automaticamente un nombre DNS dentro del cluster. El formato es:
`<nombre-service>.<namespace>.svc.cluster.local`

Por ejemplo, el Service `backend-ok-svc` en el namespace `lab-troubleshooting-test` tiene el DNS:
`backend-ok-svc.lab-troubleshooting-test.svc.cluster.local`

```bash
# Test DNS: resolver el nombre del Service desde dentro del cluster
kubectl exec -n lab-troubleshooting-test busybox-dns-test -- \
  nslookup backend-ok-svc.lab-troubleshooting-test.svc.cluster.local
```

Output esperado:

```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      backend-ok-svc.lab-troubleshooting-test.svc.cluster.local
Address 1: 10.96.x.x backend-ok-svc.lab-troubleshooting-test.svc.cluster.local
```

Que nos dice este output:
- `Server: 10.96.0.10` es CoreDNS, el servidor DNS interno de Kubernetes.
- La segunda parte muestra la IP del Service, confirmando que el DNS funciona.

Si el DNS NO funciona, verias: `nslookup: can't resolve 'backend-ok-svc...'`

```bash
# Test de conectividad HTTP usando curl
kubectl exec -n lab-troubleshooting-test curl-test -- \
  curl -s http://backend-ok-svc.lab-troubleshooting-test/
```

Output esperado (pagina de bienvenida de nginx):

```
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

Que nos dice esto: El trafico llego al Service, el Service lo enruto a uno de los Pods, y el Pod respondio correctamente.

```bash
# Verificar que el Service que corregimos ahora tiene endpoints
kubectl get endpoints -n lab-troubleshooting-test backend-broken-svc
```

Output esperado (ahora tiene IPs, antes tenia <none>):

```
NAME                  ENDPOINTS                       AGE
backend-broken-svc    10.244.0.5:80,10.244.0.6:80    8m
```

---

### Paso 7: Verificar Estado Final (5 min)

Despues de aplicar todas las correcciones, verifica el estado general del namespace.

```bash
# Ver todos los Deployments
kubectl get deployments -n lab-troubleshooting-test
```

Output esperado:

```
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
webapp-crash   1/1     1            1           15m
api-broken     1/1     1            1           15m
backend-ok     2/2     2            2           15m
```

`READY: 1/1` o `2/2` en todos los Deployments confirma que los Pods estan corriendo y listos.

```bash
# Ver todos los Pods
kubectl get pods -n lab-troubleshooting-test
```

Output esperado:

```
NAME                            READY   STATUS      RESTARTS   AGE
webapp-crash-xxxxxxx-xxxxx      1/1     Running     0          2m
api-broken-xxxxxxx-xxxxx        1/1     Running     0          2m
backend-ok-xxxxxxx-xxxxx        1/1     Running     0          15m
backend-ok-xxxxxxx-xxxxx        1/1     Running     0          15m
web-readiness-broken            0/1     Running     0          15m
busybox-dns-test                1/1     Running     0          15m
curl-test                       1/1     Running     0          15m
```

Notas sobre el estado final:
- `webapp-crash` y `api-broken` ahora muestran `Running` con `RESTARTS: 0`. Los fixes funcionaron.
- `web-readiness-broken` sigue en `0/1 READY` porque no corregimos esa probe en este laboratorio (quedaria como ejercicio adicional).
- `busybox-dns-test` y `curl-test` siguen `Running` porque los usamos para verificaciones.

```bash
# Ver los eventos recientes para confirmar que no hay nuevos errores
kubectl get events -n lab-troubleshooting-test --sort-by='.lastTimestamp' | tail -10
```

Si los fixes funcionaron correctamente, no deberia haber nuevos eventos de tipo `Warning`.

---

### Paso 8: Limpieza (1 min)

Cuando termines el laboratorio, elimina todos los recursos para liberar espacio en el cluster.

```bash
# Opcion 1: Usar el script de limpieza (recomendado)
./cleanup.sh

# Opcion 2: Eliminar el namespace completo (esto elimina TODO lo que esta dentro)
kubectl delete namespace lab-troubleshooting-test
```

Output esperado del namespace delete:

```
namespace "lab-troubleshooting-test" deleted
```

Verificar que el namespace ya no existe:

```bash
kubectl get namespace lab-troubleshooting-test
# Debe mostrar: Error from server (NotFound): namespaces "lab-troubleshooting-test" not found
```

---

## Resumen Visual: Flujo de Troubleshooting

```
PROBLEMA DETECTADO
       |
       v
kubectl get pods/nodes/svc
       |
       v
  +----+----+
  |  Estado  |
  +----+----+
       |
       +-- CrashLoopBackOff --> kubectl logs --previous --> Fix args/config
       |
       +-- ImagePullBackOff --> kubectl describe pod --> Fix image tag
       |
       +-- Pending ----------> kubectl describe pod --> Resources/PVC/Scheduler
       |
       +-- Running 0/1 ------> kubectl describe pod --> Fix readiness probe
       |
       +-- NotReady (node) --> journalctl -u kubelet --> Fix kubelet/CNI
       |
       +-- Service no funciona --> kubectl get endpoints --> Fix selectors/ports
```

---

## Donde Buscar segun el Tipo de Problema

| Problema | Donde Buscar |
|----------|-------------|
| **Pod no inicia** | `kubectl describe pod` ver Events |
| **Pod crashea repetidamente** | `kubectl logs --previous` |
| **Service no enruta trafico** | `kubectl get endpoints`, comparar selectors |
| **DNS no resuelve nombres** | CoreDNS pods, `kubectl get svc kube-dns -n kube-system` |
| **Node NotReady** | `kubectl describe node`, `journalctl -u kubelet` |
| **API Server inaccesible** | `crictl ps`, `/etc/kubernetes/manifests/` |
| **Problemas con etcd** | `etcdctl endpoint health`, verificar certificados |
| **Problemas con Storage** | `kubectl get pv,pvc`, verificar StorageClass |

---

## Preparacion CKA: Comandos Rapidos

En el examen CKA tienes tiempo limitado. Aprende a ejecutar estos comandos de forma automatica:

```bash
# DIAGNOSTICO RAPIDO (30 seg)
# Ver todos los Pods que no estan Running en todo el cluster
kubectl get pods -A | grep -v Running

# Ver estado de los Nodes
kubectl get nodes

# Ver los ultimos eventos del cluster (los mas recientes al final)
kubectl get events --sort-by='.lastTimestamp' | head -20

# LOGS (1 min)
# Logs del intento anterior (cuando el contenedor ya se reinicio)
kubectl logs <pod> --previous

# Logs de un contenedor especifico dentro de un Pod multi-container
kubectl logs <pod> -c <container>

# Logs del kubelet en el sistema operativo del Node
sudo journalctl -u kubelet -n 50 --no-pager

# NETWORKING (1 min)
# Ver Services y sus Endpoints juntos
kubectl get svc,endpoints

# Test DNS desde un Pod temporal (se elimina automaticamente al salir)
kubectl run test --image=busybox:1.28 --rm -it -- nslookup kubernetes.default

# Ver politicas de red
kubectl get networkpolicies

# STORAGE (30 seg)
# Ver PersistentVolumes y PersistentVolumeClaims
kubectl get pv,pvc

# Ver StorageClasses disponibles
kubectl get sc

# Ver detalle de un PVC con problema
kubectl describe pvc <name>

# ETCD BACKUP (2 min)
# Crear backup del estado del cluster
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /backup/snapshot.db
```
