# Lab Resumen: Pods vs Contenedores

Revision guiada de 15 minutos sobre los conceptos clave de Pods multi-container,
disenada para ejecutarse en Minikube. Ideal para repasar antes de un examen CKAD/CKA.

**Duracion:** 15 minutos | **Nivel:** Intermedio | **Archivo:** `pods-lab.yaml`

Un solo YAML despliega un namespace aislado con Pods que demuestran los cuatro
patrones clave del modulo: multi-container con shared network, PID namespace
compartido, patron sidecar con emptyDir, e init containers.

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

---

## Paso 2: Multi-container Pod y Shared Network (3 min)

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

---

## Paso 3: Shared PID Namespace (2 min)

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

---

## Paso 4: Sidecar Pattern con emptyDir (3 min)

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

---

## Paso 5: Init Container (3 min)

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
