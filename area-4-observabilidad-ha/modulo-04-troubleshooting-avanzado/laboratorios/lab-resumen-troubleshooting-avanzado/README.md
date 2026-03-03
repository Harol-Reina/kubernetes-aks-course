# Resumen Rapido: Troubleshooting Avanzado

**Duracion:** 60 minutos | **Nivel:** Principiante | **Archivo:** `troubleshooting-avanzado-lab.yaml`

Este laboratorio resume los conceptos clave del Capitulo 37: Troubleshooting Avanzado. Despliega 6 recursos con errores intencionales y 1 Pod de debugging para practicar el diagnostico sistematico de los fallos mas comunes en Kubernetes: CrashLoopBackOff, OOMKilled, Pending por recursos imposibles, ImagePullBackOff, errores de configuracion, y readiness probe fallida.

---

## Indice

1. [La Analogia del Detective](#la-analogia-del-detective)
2. [Conceptos Previos: Estados de Pod y Framework de Diagnostico](#conceptos-previos)
3. [Diagrama ASCII: Flujo de Diagnostico](#diagrama-ascii-flujo-de-diagnostico)
4. [Escenarios del Laboratorio](#escenarios-del-laboratorio)
5. [Ejercicio Practico (60 min)](#ejercicio-practico-60-min)
   - [Paso 1: Desplegar los recursos (2 min)](#paso-1-desplegar-los-recursos-2-min)
   - [Paso 2: Vista general - identificar los fallos (5 min)](#paso-2-vista-general---identificar-los-fallos-5-min)
   - [Paso 3: Diagnosticar CrashLoopBackOff (8 min)](#paso-3-diagnosticar-crashloopbackoff-8-min)
   - [Paso 4: Diagnosticar OOMKilled (8 min)](#paso-4-diagnosticar-oomkilled-8-min)
   - [Paso 5: Diagnosticar Pending por recursos imposibles (7 min)](#paso-5-diagnosticar-pending-por-recursos-imposibles-7-min)
   - [Paso 6: Diagnosticar ImagePullBackOff (7 min)](#paso-6-diagnosticar-imagepullbackoff-7-min)
   - [Paso 7: Diagnosticar CreateContainerConfigError (7 min)](#paso-7-diagnosticar-createcontainerconfigerror-7-min)
   - [Paso 8: Diagnosticar Readiness Probe fallida (7 min)](#paso-8-diagnosticar-readiness-probe-fallida-7-min)
6. [Resumen de Hallazgos](#resumen-de-hallazgos)
7. [Limpieza](#limpieza)

---

## La Analogia del Detective

El troubleshooting es como ser un detective: cuando algo falla, necesitas pistas (logs), evidencia (eventos), testigos (metricas), y un metodo sistematico para encontrar al culpable.

En Kubernetes cada fallo deja rastros exactamente igual que una escena del crimen:

- **Las pistas** son los logs del contenedor (`kubectl logs`). Te dicen que ocurrio desde dentro.
- **La evidencia** son los Events del objeto (`kubectl describe`). Te dicen que hizo Kubernetes externamente.
- **Los testigos** son las metricas del nodo (`kubectl top`). Te dicen si el problema fue de recursos.
- **El metodo** es el framework Pod -> Container -> Node: siempre bajas de nivel hasta encontrar la causa raiz.

El error visible que reporta el usuario raramente es el error real. Un Pod en CrashLoopBackOff puede estar fallando por una imagen incorrecta, un argumento invalido, una variable de entorno que no se cargo, o un archivo de configuracion que no existe. Tu trabajo es bajar por las capas hasta encontrar donde esta el error real.

---

## Conceptos Previos

Si ya conoces estos conceptos puedes saltar directamente a los pasos del ejercicio. Si no, leelos ahora porque los necesitaras para interpretar los resultados.

### Estados de Pod

Un Pod no es simplemente "funcionando" o "roto". Kubernetes usa estados precisos que ya te dicen mucho sobre el tipo de problema antes de ejecutar un solo comando de diagnostico.

| Estado | Que significa | Primera pista |
|--------|--------------|---------------|
| `Pending` | El Pod fue aceptado pero no tiene nodo asignado | `kubectl describe pod` ver Events: scheduler no puede encontrar nodo |
| `Running` con `READY: 1/1` | El contenedor esta ejecutandose y listo | Estado sano |
| `Running` con `READY: 0/1` | El contenedor esta vivo pero no pasa la readiness probe | `kubectl describe pod` ver Readiness |
| `CrashLoopBackOff` | El contenedor arranca, falla, Kubernetes lo reinicia, y el ciclo se repite | `kubectl logs <pod> --previous` |
| `ImagePullBackOff` | Kubernetes no puede descargar la imagen del contenedor | `kubectl describe pod` ver Events: "Failed to pull image" |
| `OOMKilled` | El kernel mato el proceso porque excedio el limite de memoria | `kubectl describe pod` ver Last State: exit code 137 |
| `CreateContainerConfigError` | No se puede crear el contenedor porque falta un ConfigMap o Secret referenciado | `kubectl describe pod` ver Events: "not found" |
| `Init:0/1` | Un init container esta esperando o fallando | `kubectl logs <pod> -c <init-container>` |

La columna `RESTARTS` en `kubectl get pods` es otro indicador clave: un numero alto (5, 10, 50) confirma que el contenedor esta fallando repetidamente.

### El Framework de Diagnostico: Pod -> Container -> Node

Cada vez que algo falla, baja por estas tres capas en orden. No pases a la siguiente capa sin haber descartado la anterior.

```
+---------------------+
|        POD          |  <- Capa 1: empieza aqui siempre
|  Estado, Events,    |
|  Scheduling         |
+---------------------+
         |
         v (si el Pod parece OK)
+---------------------+
|     CONTENEDOR      |  <- Capa 2: logs, config, imagen
|  Logs, Exit codes,  |
|  Recursos, Probes   |
+---------------------+
         |
         v (si el contenedor parece OK)
+---------------------+
|       NODO          |  <- Capa 3: kubelet, kernel, runtime
|  kubelet logs,      |
|  disk/memory        |
|  pressure, crictl   |
+---------------------+
```

El 80% de los problemas se resuelven en la capa 1 o 2. La capa 3 es para fallos del sistema operativo o del container runtime.

### Los 4 Comandos Fundamentales

Estos 4 comandos resuelven el 90% de los problemas de troubleshooting. Aprende a ejecutarlos en orden antes de intentar cualquier correccion.

**1. `kubectl get pods`** - Vision general del estado

```bash
kubectl get pods -n <namespace>
```

Te da el estado de todos los Pods de un vistazo. Busca en STATUS cualquier cosa que no sea `Running` o `Completed`. Busca en RESTARTS numeros altos.

**2. `kubectl describe pod <nombre>`** - Detalle completo y Events

```bash
kubectl describe pod <nombre> -n <namespace>
```

Es el comando mas importante para troubleshooting. Muestra toda la configuracion del Pod y, lo mas valioso, la seccion **Events** al final. Los Events son el registro cronologico de todo lo que le paso al Pod: intentos de scheduling, descargas de imagen, fallos de probe, reinicios.

Siempre lee la seccion Events completa. El ultimo evento suele ser la causa raiz.

**3. `kubectl logs <nombre> --previous`** - Mensajes del contenedor que ya murio

```bash
kubectl logs <nombre> -n <namespace> --previous
```

El flag `--previous` es fundamental. Si el contenedor ya fallo y se reinicio, los logs actuales son del nuevo intento (que puede no tener logs aun). Los logs del intento que fallo solo se ven con `--previous`.

**4. `kubectl get events`** - Historial completo del namespace

```bash
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

Muestra todos los eventos de todos los recursos del namespace, en orden cronologico. Util cuando no sabes exactamente que recurso fallo.

---

## Diagrama ASCII: Flujo de Diagnostico

Usa este flujo cada vez que encuentres un Pod que no esta `Running` con `READY: 1/1`.

```
ALERTA: Pod no esta Running/Ready
            |
            v
  kubectl get pods -n <ns>
            |
            v
    +-------+-------+
    |  Cual es el   |
    |    STATUS?    |
    +-------+-------+
            |
    +-------+--------+--------+----------+----------+----------+
    |                |        |          |          |          |
    v                v        v          v          v          v
Pending       CrashLoop   ImagePull  OOMKilled  CreateConfig  Running
    |         BackOff     BackOff       |        ConfigError   0/1
    |              |         |          |            |          |
    v              v         v          v            v          v
describe       logs        describe   describe    describe   describe
buscar         --previous  buscar     buscar      buscar     buscar
"Insufficient" error real  "manifest  exit code   "not       Readiness
"Unschedulable" o describe unknown"   137         found"     probe fail
    |              |         |          |            |          |
    v              v         v          v            v          v
Fix: reducir   Fix: corregir Fix: corregir Fix: aumentar Fix: crear  Fix: corregir
resources      comando/args  imagen/tag    memory limit  ConfigMap/  puerto/ruta
o agregar      o env vars                               Secret      del probe
nodos
```

---

## Escenarios del Laboratorio

El archivo `troubleshooting-avanzado-lab.yaml` crea un namespace `lab-troubleshooting-avanzado` con los siguientes recursos:

| Recurso | Tipo | Estado esperado | Error introducido |
|---------|------|-----------------|-------------------|
| `crashloop-demo` | Pod | CrashLoopBackOff | Argumento `--config-invalido` que nginx rechaza |
| `oom-demo` | Pod | OOMKilled / CrashLoopBackOff | Proceso que consume 200Mi con limite de 64Mi |
| `pending-demo` | Pod | Pending | Request de 99 CPU cores (imposible) |
| `imagen-incorrecta` | Deployment | ImagePullBackOff | Tag de imagen `version-que-no-existe-99999` |
| `config-error` | Pod | CreateContainerConfigError | Referencia a ConfigMap y Secret inexistentes |
| `readiness-fail` | Pod | Running 0/1 | Readiness probe en puerto 9090 (nginx usa 80) |
| `test-tools` | Pod | Running 1/1 | Pod de debugging (busybox con sleep) |
| `lab-referencia` | ConfigMap | Active | Datos de referencia para el lab |

---

## Ejercicio Practico (60 min)

### Paso 1: Desplegar los recursos (2 min)

Aplica el archivo YAML para crear todos los recursos del laboratorio en el namespace dedicado.

```bash
kubectl apply -f troubleshooting-avanzado-lab.yaml
```

Output esperado:

```
namespace/lab-troubleshooting-avanzado created
configmap/lab-referencia created
pod/crashloop-demo created
pod/oom-demo created
pod/pending-demo created
deployment.apps/imagen-incorrecta created
pod/config-error created
pod/readiness-fail created
pod/test-tools created
```

Cada linea `created` confirma que Kubernetes acepto el recurso. Pero "aceptado" no es igual a "funcionando". Varios van a fallar inmediatamente o en los proximos segundos.

Cambia al namespace del laboratorio para no tener que escribir `-n lab-troubleshooting-avanzado` en cada comando:

```bash
kubectl config set-context --current --namespace=lab-troubleshooting-avanzado
```

Output esperado:

```
Context "minikube" modified.
```

---

### Paso 2: Vista general - identificar los fallos (5 min)

El primer paso del framework de diagnostico es siempre obtener una vision general. No empieces a investigar un Pod especifico sin haber visto primero el cuadro completo.

```bash
kubectl get pods
```

Output esperado (los tiempos y contadores pueden variar segun cuanto tiempo haya pasado desde el apply):

```
NAME                                READY   STATUS                       RESTARTS   AGE
config-error                        0/1     CreateContainerConfigError   0          15s
crashloop-demo                      0/1     CrashLoopBackOff             2          30s
imagen-incorrecta-xxxxxxxxx-xxxxx   0/1     ImagePullBackOff             0          15s
oom-demo                            0/1     OOMKilled                    1          15s
pending-demo                        0/1     Pending                      0          15s
readiness-fail                      0/1     Running                      0          15s
test-tools                          1/1     Running                      0          15s
```

Lo que debes observar antes de investigar nada:

- **`test-tools`**: `1/1 Running` es el unico Pod sano. Lo usaremos para pruebas de red si es necesario.
- **`crashloop-demo`**: `CrashLoopBackOff` con `RESTARTS` creciendo. El contenedor falla y Kubernetes lo reinicia.
- **`oom-demo`**: `OOMKilled` o `CrashLoopBackOff` segun el momento. El proceso fue matado por falta de memoria.
- **`pending-demo`**: `Pending` con `RESTARTS: 0`. No le han asignado nodo. El scheduler no puede programarlo.
- **`imagen-incorrecta`**: `ImagePullBackOff`. La imagen no se puede descargar.
- **`config-error`**: `CreateContainerConfigError`. Falta un ConfigMap o Secret referenciado.
- **`readiness-fail`**: `Running` pero `0/1 READY`. El contenedor esta vivo pero la readiness probe falla.

Ahora tienes el mapa completo. Investiga cada fallo en orden.

---

### Paso 3: Diagnosticar CrashLoopBackOff (8 min)

**Que deberia hacer este Pod cuando funciona correctamente:**
El Pod `crashloop-demo` ejecuta nginx y lo mantiene corriendo. Deberia mostrar `Running` con `READY: 1/1`.

**Que error fue introducido:**
El contenedor nginx recibe el argumento `--config-invalido`. Nginx no reconoce ese argumento, imprime un error en stderr, y termina con exit code distinto de 0. Kubernetes lo reinicia, nginx vuelve a fallar, y el ciclo continua indefinidamente.

**Como diagnosticar:**

```bash
kubectl get pod crashloop-demo
```

Output esperado:

```
NAME             READY   STATUS             RESTARTS   AGE
crashloop-demo   0/1     CrashLoopBackOff   3          1m
```

El numero en `RESTARTS` sigue creciendo. Cada reinicio tarda mas que el anterior (1s, 2s, 4s, 8s...). Eso es el "backoff" en CrashLoopBackOff: Kubernetes espera cada vez mas antes de reintentar.

Ahora lee los logs del intento anterior. Los logs del intento actual pueden estar vacios si el contenedor todavia no arranco:

```bash
kubectl logs crashloop-demo --previous
```

Output esperado:

```
nginx: invalid option: "--config-invalido"
```

Nginx imprime exactamente que argumento no reconoce. Esta es la causa raiz: el argumento `--config-invalido` no es un flag valido de nginx.

Confirma con `describe` para ver como Kubernetes registro el fallo:

```bash
kubectl describe pod crashloop-demo | grep -A 15 "Events:"
```

Output esperado en la seccion Events:

```
Events:
  Type     Reason     Age              From               Message
  ----     ------     ----             ----               -------
  Normal   Scheduled  2m               default-scheduler  Successfully assigned ...
  Normal   Pulled     2m               kubelet            Container image "nginx:1.25-alpine" already present
  Normal   Created    2m               kubelet            Created container nginx
  Normal   Started    2m               kubelet            Started container nginx
  Warning  BackOff    30s (x3 over 1m) kubelet            Back-off restarting failed container nginx in pod crashloop-demo
```

El evento `Back-off restarting failed container` confirma el ciclo de reinicio.

**Conclusion del escenario:**
- **Estado visible:** CrashLoopBackOff
- **Causa raiz:** argumento invalido pasado al comando principal del contenedor
- **Comando clave:** `kubectl logs <pod> --previous`
- **Fix:** eliminar el argumento `--config-invalido` del spec del Pod

---

### Paso 4: Diagnosticar OOMKilled (8 min)

**Que deberia hacer este Pod cuando funciona correctamente:**
El Pod `oom-demo` ejecuta un proceso stress que simula carga de memoria. Si el limite de memoria fuera suficiente, el proceso correria sin problemas.

**Que error fue introducido:**
El proceso intenta reservar 200 megabytes de RAM, pero el limite del contenedor es de 64 megabytes. Cuando el proceso supera ese limite, el kernel de Linux activa el OOM Killer (Out-Of-Memory Killer) y mata el proceso con la senal SIGKILL (exit code 137). Kubernetes detecta que el contenedor murio y lo reinicia.

**Como diagnosticar:**

```bash
kubectl get pod oom-demo
```

Output esperado (puede estar en OOMKilled o en CrashLoopBackOff si ya se reinicio varias veces):

```
NAME       READY   STATUS             RESTARTS   AGE
oom-demo   0/1     OOMKilled          1          45s
```

o

```
NAME       READY   STATUS             RESTARTS   AGE
oom-demo   0/1     CrashLoopBackOff   3          2m
```

El dato clave no esta en el STATUS actual sino en el historial. Usa `describe` para ver el estado anterior del contenedor:

```bash
kubectl describe pod oom-demo | grep -A 10 "Last State:"
```

Output esperado:

```
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      ...
      Finished:     ...
```

El `Reason: OOMKilled` y el `Exit Code: 137` son la firma definitiva de un problema de memoria. El exit code 137 significa SIGKILL (128 + 9), que es la senal que envia el kernel cuando el OOM Killer actua.

Ahora verifica cuanto memoria tenia configurada el contenedor:

```bash
kubectl describe pod oom-demo | grep -A 6 "Limits:"
```

Output esperado:

```
    Limits:
      cpu:     100m
      memory:  64Mi
    Requests:
      cpu:     50m
      memory:  32Mi
```

El limite es 64Mi pero el proceso intenta usar 200Mi. Ahi esta la discrepancia.

Revisa tambien los eventos del Pod:

```bash
kubectl describe pod oom-demo | grep -A 10 "Events:"
```

Output esperado:

```
Events:
  Type     Reason     Age              From      Message
  ----     ------     ----             ----      -------
  Warning  OOMKilling 1m               kubelet   Memory limit reached
  Warning  BackOff    30s (x2 over 1m) kubelet   Back-off restarting failed container stress
```

**Conclusion del escenario:**
- **Estado visible:** OOMKilled (o CrashLoopBackOff despues de varios reinicios)
- **Causa raiz:** el proceso consume mas memoria que el limite configurado
- **Senal diagnostica:** exit code 137 en `Last State`
- **Comando clave:** `kubectl describe pod <nombre>` buscar `Last State: OOMKilled`
- **Fix:** aumentar el memory limit del contenedor o reducir el consumo de memoria de la aplicacion

---

### Paso 5: Diagnosticar Pending por recursos imposibles (7 min)

**Que deberia hacer este Pod cuando funciona correctamente:**
El Pod `pending-demo` ejecuta nginx y deberia arrancar en cuestion de segundos en cualquier nodo del cluster.

**Que error fue introducido:**
El Pod solicita 99 CPU cores como request de CPU. Ningun nodo real en un cluster de desarrollo o produccion tiene 99 CPUs libres. El scheduler de Kubernetes busca un nodo que cumpla ese requisito, no lo encuentra, y el Pod queda en estado Pending indefinidamente.

**Como diagnosticar:**

```bash
kubectl get pod pending-demo
```

Output esperado:

```
NAME           READY   STATUS    RESTARTS   AGE
pending-demo   0/1     Pending   0          3m
```

Nota que `RESTARTS` es 0. El contenedor nunca llego a arrancar: el problema esta antes de que Kubernetes intente iniciar el contenedor. El scheduler no pudo asignar el Pod a ningun nodo.

El `describe` es la herramienta correcta aqui porque el problema esta en la capa de scheduling, no en los logs del contenedor (que estan vacios porque el contenedor nunca inicio):

```bash
kubectl describe pod pending-demo | grep -A 15 "Events:"
```

Output esperado:

```
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  3m    default-scheduler  0/1 nodes are available: 1 Insufficient cpu.
                                                      preemption: 0/1 nodes are available:
                                                      1 No preemption victims found for incoming pod.
```

El mensaje `Insufficient cpu` y `0/1 nodes are available` confirman que ningun nodo tiene suficiente CPU para cumplir el request de 99 cores.

Puedes confirmar los requests configurados:

```bash
kubectl describe pod pending-demo | grep -A 6 "Requests:"
```

Output esperado:

```
    Requests:
      cpu:     99
      memory:  1Mi
```

Un cluster tipico de Minikube tiene 2 CPUs. La peticion de 99 es imposible de satisfacer.

Tambien puedes ver la capacidad de los nodos del cluster:

```bash
kubectl get nodes -o custom-columns="NODO:.metadata.name,CPU:.status.capacity.cpu,MEMORIA:.status.capacity.memory"
```

Output esperado:

```
NODO       CPU   MEMORIA
minikube   2     4026520Ki
```

Con 2 CPUs disponibles en el nodo y el Pod pidiendo 99, la matematica no funciona.

**Conclusion del escenario:**
- **Estado visible:** Pending (sin cambio, puede durar horas o dias)
- **Causa raiz:** resource request imposible de satisfacer por ningun nodo
- **Senal diagnostica:** `FailedScheduling` con `Insufficient cpu/memory` en Events
- **Comando clave:** `kubectl describe pod <nombre>` buscar la seccion Events con `FailedScheduling`
- **Fix:** reducir el resource request a valores reales, o agregar nodos con mayor capacidad al cluster

---

### Paso 6: Diagnosticar ImagePullBackOff (7 min)

**Que deberia hacer este recurso cuando funciona correctamente:**
El Deployment `imagen-incorrecta` deberia crear un Pod con nginx corriendo. Deberias ver 1/1 Pod en estado Running.

**Que error fue introducido:**
La imagen especificada es `nginx:version-que-no-existe-99999`. Ese tag no existe en DockerHub ni en ningun registry. Kubernetes intenta descargar la imagen, el registry responde con "manifest unknown" (el tag no existe), Kubernetes espera un poco y lo intenta de nuevo, y el ciclo continua aumentando el tiempo de espera entre intentos.

**Como diagnosticar:**

Primero busca el Pod creado por el Deployment:

```bash
kubectl get pods -l scenario=imagepull
```

Output esperado:

```
NAME                                 READY   STATUS             RESTARTS   AGE
imagen-incorrecta-xxxxxxxxx-xxxxx    0/1     ImagePullBackOff   0          2m
```

El `RESTARTS` suele ser 0 en ImagePullBackOff porque el contenedor nunca llego a arrancar. El error ocurre antes de intentar iniciar el proceso.

```bash
kubectl describe pod -l scenario=imagepull | grep -A 20 "Events:"
```

Output esperado en Events:

```
Events:
  Type     Reason     Age               From               Message
  ----     ------     ----              ----               -------
  Normal   Scheduled  2m                default-scheduler  Successfully assigned ...
  Normal   Pulling    2m                kubelet            Pulling image "nginx:version-que-no-existe-99999"
  Warning  Failed     2m                kubelet            Failed to pull image "nginx:version-que-no-existe-99999":
                                                           rpc error: code = Unknown desc = failed to pull and
                                                           unpack image "docker.io/nginx:version-que-no-existe-99999":
                                                           failed to resolve reference "docker.io/nginx:version-que-no-existe-99999":
                                                           unexpected status code 404 Not Found
  Warning  Failed     2m                kubelet            Error: ErrImagePull
  Warning  BackOff    90s (x3 over 2m)  kubelet            Back-off pulling image "nginx:version-que-no-existe-99999"
```

Los eventos te dan tres piezas de informacion esenciales:
1. El nombre exacto de la imagen que no se pudo descargar: `nginx:version-que-no-existe-99999`
2. La respuesta del registry: `404 Not Found` o `manifest unknown`
3. El estado actual: `Back-off pulling image` (backoff creciente entre reintentos)

**Diferencia entre ErrImagePull e ImagePullBackOff:**
- `ErrImagePull` es el error inmediato: el primer intento de descarga fallo.
- `ImagePullBackOff` aparece despues del primer fallo: Kubernetes esta esperando antes de intentar de nuevo (backoff).

**Conclusion del escenario:**
- **Estado visible:** ImagePullBackOff
- **Causa raiz:** tag de imagen inexistente en el registry
- **Senal diagnostica:** `Failed to pull image` con `404 Not Found` o `manifest unknown` en Events
- **Comando clave:** `kubectl describe pod <nombre>` buscar la seccion Events
- **Fix:** corregir el tag de imagen a uno que exista (`nginx:1.25-alpine`, `nginx:latest`, etc.)

---

### Paso 7: Diagnosticar CreateContainerConfigError (7 min)

**Que deberia hacer este Pod cuando funciona correctamente:**
El Pod `config-error` deberia arrancar nginx con algunas variables de entorno cargadas desde un ConfigMap y un Secret.

**Que error fue introducido:**
El Pod referencia un ConfigMap llamado `config-inexistente` y un Secret llamado `secret-inexistente`. Ninguno de los dos existe en el namespace. Kubernetes acepta el manifiesto del Pod (no valida referencias en el momento del apply), pero cuando intenta crear el contenedor, el kubelet no puede resolver las variables de entorno y el Pod queda en `CreateContainerConfigError`.

**Como diagnosticar:**

```bash
kubectl get pod config-error
```

Output esperado:

```
NAME           READY   STATUS                       RESTARTS   AGE
config-error   0/1     CreateContainerConfigError   0          3m
```

Igual que con Pending, `RESTARTS: 0` indica que el contenedor nunca llego a ejecutarse. El error ocurre al intentar configurar el contenedor antes de iniciarlo.

```bash
kubectl describe pod config-error | grep -A 20 "Events:"
```

Output esperado en Events:

```
Events:
  Type     Reason     Age   From               Message
  ----     ------     ----  ----               -------
  Normal   Scheduled  3m    default-scheduler  Successfully assigned ...
  Normal   Pulled     3m    kubelet            Container image "nginx:1.25-alpine" already present
  Warning  Failed     3m    kubelet            Error: configmaps "config-inexistente" not found
```

El error `configmaps "config-inexistente" not found` identifica exactamente que recurso falta. Si el Secret tampoco existiera sin el ConfigMap, veriamos primero el error del ConfigMap (Kubernetes valida las referencias en el orden en que aparecen en el spec).

Para confirmar que referencias hace el Pod y cuales no existen:

```bash
# Ver que ConfigMaps y Secrets referencia el Pod
kubectl describe pod config-error | grep -E "configMapKeyRef|secretKeyRef|ConfigMap|Secret"
```

Output esperado:

```
    DB_HOST:     <set to the key 'database_host' in ConfigMap 'config-inexistente'>  Optional: false
    DB_PASSWORD: <set to the key 'password' in Secret 'secret-inexistente'>          Optional: false
```

```bash
# Confirmar que esos ConfigMaps y Secrets no existen
kubectl get configmap config-inexistente 2>&1
kubectl get secret secret-inexistente 2>&1
```

Output esperado:

```
Error from server (NotFound): configmaps "config-inexistente" not found
Error from server (NotFound): secrets "secret-inexistente" not found
```

**Conclusion del escenario:**
- **Estado visible:** CreateContainerConfigError
- **Causa raiz:** el Pod referencia ConfigMaps o Secrets que no existen en el namespace
- **Senal diagnostica:** `configmaps "nombre" not found` o `secrets "nombre" not found` en Events
- **Comando clave:** `kubectl describe pod <nombre>` buscar en Events "not found"
- **Fix:** crear el ConfigMap y el Secret que faltan, o corregir las referencias en el spec del Pod

---

### Paso 8: Diagnosticar Readiness Probe fallida (7 min)

**Que deberia hacer este Pod cuando funciona correctamente:**
El Pod `readiness-fail` ejecuta nginx. La readiness probe deberia confirmar que el servidor esta listo para recibir trafico, y el Pod deberia aparecer como `1/1 READY`.

**Que error fue introducido:**
La readiness probe hace una peticion HTTP a la ruta `/health` en el puerto `9090`. Nginx escucha en el puerto `80`, no en el `9090`. Kubernetes no puede conectarse al puerto 9090 porque nada esta escuchando ahi. La probe falla constantemente y el Pod queda en `Running` pero `READY: 0/1`.

**Como diagnosticar:**

```bash
kubectl get pod readiness-fail
```

Output esperado:

```
NAME             READY   STATUS    RESTARTS   AGE
readiness-fail   0/1     Running   0          5m
```

Aqui hay una distincion critica respecto a los otros escenarios: el STATUS es `Running` (el contenedor esta vivo y el proceso de nginx se esta ejecutando). Pero `READY: 0/1` significa que la readiness probe falla. El Pod existe pero no esta disponible para recibir trafico de ningun Service.

Ademas, `RESTARTS: 0` porque la readiness probe NO reinicia el contenedor. Solo lo excluye de los Endpoints de los Services. Esa es la diferencia fundamental entre readiness y liveness probe.

```bash
kubectl describe pod readiness-fail | grep -A 10 "Readiness:"
```

Output esperado:

```
    Readiness:      http-get http://:9090/health delay=5s timeout=1s period=5s #success=1 #failure=3
```

El probe esta configurado en el puerto `9090` y la ruta `/health`. Ahora confirma en los Events que esta fallando:

```bash
kubectl describe pod readiness-fail | grep -A 15 "Events:"
```

Output esperado en Events:

```
Events:
  Type     Reason     Age                From     Message
  ----     ------     ----               ----     -------
  Normal   Scheduled  5m                 default-scheduler  Successfully assigned ...
  Normal   Pulling    5m                 kubelet  Pulling image "nginx:1.25-alpine"
  Normal   Pulled     5m                 kubelet  Successfully pulled image
  Normal   Created    5m                 kubelet  Created container nginx
  Normal   Started    5m                 kubelet  Started container nginx
  Warning  Unhealthy  10s (x30 over 5m)  kubelet  Readiness probe failed:
                                                   Get "http://10.x.x.x:9090/health":
                                                   dial tcp 10.x.x.x:9090: connect: connection refused
```

El `connection refused` en el puerto `9090` confirma que nada esta escuchando en ese puerto. Nginx escucha en el `80`.

Para comparar, asi se veria la probe si estuviera correctamente configurada:

```
# Configuracion correcta (lo que deberia decir):
Readiness:  http-get http://:80/ delay=5s timeout=1s period=5s
```

**Diferencia clave entre Liveness y Readiness probe:**

| Probe | Si falla... | Efecto |
|-------|-------------|--------|
| `livenessProbe` | Kubernetes mata y reinicia el contenedor | RESTARTS aumenta |
| `readinessProbe` | Kubernetes quita el Pod de los Endpoints de Services | READY: 0/1, RESTARTS no cambia |

Con la readiness probe fallando, si hubiera un Service seleccionando este Pod, el Pod no recibiria trafico aunque el proceso de nginx este funcionando correctamente. El Service solo enruta trafico a Pods con `READY: 1/1`.

**Conclusion del escenario:**
- **Estado visible:** Running con READY: 0/1
- **Causa raiz:** readiness probe configurada en puerto o ruta incorrectos
- **Senal diagnostica:** `Readiness probe failed: connection refused` en Events
- **Comando clave:** `kubectl describe pod <nombre>` buscar seccion "Readiness:" y Events "Unhealthy"
- **Fix:** corregir el puerto de la readiness probe de `9090` a `80`

---

## Resumen de Hallazgos

Despues de completar todos los pasos, debes poder llenar esta tabla de memoria. Si no recuerdas alguna celda, vuelve al paso correspondiente.

| Pod | Estado visto | Causa raiz | Comando que lo revelo |
|-----|-------------|------------|----------------------|
| `crashloop-demo` | CrashLoopBackOff | Argumento `--config-invalido` no reconocido por nginx | `kubectl logs --previous` |
| `oom-demo` | OOMKilled / CrashLoopBackOff | Proceso consume 200Mi con limite de 64Mi | `kubectl describe` -> `Last State: OOMKilled, Exit Code: 137` |
| `pending-demo` | Pending | Request de 99 CPU imposible de satisfacer | `kubectl describe` -> Events: `Insufficient cpu` |
| `imagen-incorrecta` | ImagePullBackOff | Tag de imagen inexistente en DockerHub | `kubectl describe` -> Events: `Failed to pull image` |
| `config-error` | CreateContainerConfigError | ConfigMap y Secret referenciados no existen | `kubectl describe` -> Events: `not found` |
| `readiness-fail` | Running 0/1 | Readiness probe en puerto 9090 (nginx usa 80) | `kubectl describe` -> Events: `connection refused` |

### Patron general aprendido

Cada estado tiene una firma diagnostica:

```
CrashLoopBackOff  ->  kubectl logs --previous  (mensaje de error del proceso)
OOMKilled         ->  kubectl describe         (Last State: exit code 137)
Pending           ->  kubectl describe Events  (FailedScheduling: Insufficient)
ImagePullBackOff  ->  kubectl describe Events  (Failed to pull image: 404)
ConfigError       ->  kubectl describe Events  (not found)
Running 0/1       ->  kubectl describe Events  (Unhealthy: probe failed)
```

---

## Limpieza

Cuando termines el laboratorio, elimina todos los recursos para liberar espacio en el cluster.

Primero restaura el namespace por defecto en tu contexto:

```bash
kubectl config set-context --current --namespace=default
```

Luego ejecuta el script de limpieza:

```bash
./cleanup.sh
```

Output esperado:

```
Iniciando limpieza del Lab Resumen: Troubleshooting Avanzado...

  ✓ namespace/lab-troubleshooting-avanzado eliminado (todos los recursos incluidos)

Limpieza completada!
```

O elimina el namespace directamente:

```bash
kubectl delete namespace lab-troubleshooting-avanzado
```

Output esperado:

```
namespace "lab-troubleshooting-avanzado" deleted
```

Verifica que el namespace ya no existe:

```bash
kubectl get namespace lab-troubleshooting-avanzado
```

Output esperado:

```
Error from server (NotFound): namespaces "lab-troubleshooting-avanzado" not found
```

---

*Capitulo 37 - Troubleshooting Avanzado | Area 4: Observabilidad y Alta Disponibilidad*
