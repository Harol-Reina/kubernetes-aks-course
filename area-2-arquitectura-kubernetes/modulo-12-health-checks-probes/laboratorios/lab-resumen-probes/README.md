# Resumen Practico: Health Checks y Probes

**Duracion:** 15 minutos | **Nivel:** Repaso integral | **Archivo:** `probes-lab.yaml`

Un solo YAML despliega Pods con livenessProbe (HTTP y exec), un Deployment con readinessProbe y Service, un Pod con startupProbe, probes combinadas (patron produccion), y un Pod con probe rota para troubleshooting, usando Minikube.

---

## Conceptos Previos (Leer si eres nuevo en Kubernetes)

### Por que necesitamos Health Checks?

Cuando un contenedor se ejecuta dentro de un Pod, pueden ocurrir dos problemas que Kubernetes no puede detectar por si solo:

1. **El contenedor se cuelga (deadlock):** El proceso sigue corriendo (desde el punto de vista del sistema operativo esta "vivo"), pero internamente entro en un estado del que no puede salir. Por ejemplo, una aplicacion Java que tiene todos sus hilos bloqueados esperandose entre si. El contenedor parece estar bien, pero no responde a ninguna peticion.

2. **El contenedor no esta listo todavia:** Una aplicacion puede tardar 60 segundos en arrancar porque necesita cargar datos de una base de datos o calentar una cache. Si Kubernetes empieza a enviarle trafico antes de que este lista, los usuarios recibiran errores.

Las **probes** son la solucion: son verificaciones periodicas que kubelet (el agente de Kubernetes en cada nodo) ejecuta contra cada contenedor para saber su estado real.

### La analogia del hospital

Imagina que los contenedores son pacientes en un hospital y kubelet es el medico de guardia:

- **Liveness Probe** - "Doctor, el paciente esta vivo?"
  Si el paciente no responde (fallo), el medico lo reanima reiniciando el contenedor. Es la pregunta mas basica: existe vida?

- **Readiness Probe** - "Doctor, el paciente puede recibir visitas?"
  El paciente puede estar vivo pero aun recuperandose de una operacion. Si no esta listo, el medico no deja pasar visitas (el Service no le envia trafico) hasta que se recupere.

- **Startup Probe** - "Doctor, el paciente ya termino de prepararse para el dia?"
  Algunos pacientes necesitan mucho tiempo por la manana para alistarse. La startup probe da ese tiempo sin que el medico interrumpa preguntando "estas vivo?" cada 10 segundos antes de que termine.

---

## Que son los Health Checks

Los **Health Checks** en Kubernetes usan tres tipos de probes para monitorear contenedores:

- **Liveness Probe**: Verifica si el contenedor esta vivo. Si falla N veces seguidas, kubelet destruye y reinicia el contenedor automaticamente.
- **Readiness Probe**: Verifica si el contenedor esta listo para recibir trafico. Si falla, Kubernetes retira su IP de la lista de destinos del Service (Endpoints) hasta que vuelva a pasar.
- **Startup Probe**: Protege apps con inicio lento. Mientras no pase, liveness y readiness estan deshabilitadas para no reiniciar el contenedor prematuramente.

```
Health Checks en lab-probes
├── liveness-http       → HTTP GET a / (reinicio si falla)
├── liveness-exec       → exec cat /tmp/healthy (se borra a los 30s)
├── webapp-ready (3r)   → readinessProbe + Service (trafico controlado)
├── slow-startup-app    → startupProbe protege durante arranque
├── combined-probes     → Las 3 probes juntas (patron produccion)
├── broken-probe        → Probe rota para diagnostico (CrashLoopBackOff)
└── test-tools          → Pod de verificacion
```

---

## Conceptos Cubiertos en Este Lab

| Concepto | Que demuestra |
|----------|---------------|
| **Liveness HTTP GET** | Reinicio automatico cuando el endpoint no responde 200 |
| **Liveness Exec** | Reinicio cuando un comando retorna exit code != 0 |
| **Readiness + Service** | Solo Pods con readiness passing aparecen en Endpoints |
| **Startup Probe** | Proteccion durante arranque lento sin interferir con liveness |
| **Probes combinadas** | Flujo startup → liveness + readiness (patron produccion) |
| **Troubleshooting** | Diagnosticar CrashLoopBackOff con describe, logs, events |
| **Parametros de probe** | initialDelaySeconds, periodSeconds, failureThreshold, timeoutSeconds |

---

## Diagrama Visual

```
                    ┌─────────────────────────────────────────────┐
                    │         NAMESPACE: lab-probes                │
                    │                                             │
  ┌─────────────────┼─────────────────────────────────────────────┤
  │ Liveness        │                                             │
  │                 │  liveness-http  (HTTP GET /:80)              │
  │                 │  liveness-exec  (exec cat /tmp/healthy)      │
  ├─────────────────┼─────────────────────────────────────────────┤
  │ Readiness       │                                             │
  │                 │  webapp-ready (3 replicas + Service)         │
  │                 │  Service webapp-ready (ClusterIP:80)         │
  ├─────────────────┼─────────────────────────────────────────────┤
  │ Startup         │                                             │
  │                 │  slow-startup-app (startup + liveness + rd)  │
  │                 │  combined-probes (las 3 probes juntas)       │
  ├─────────────────┼─────────────────────────────────────────────┤
  │ Troubleshooting │                                             │
  │                 │  broken-probe (/nonexistent → CrashLoop)    │
  └─────────────────┼─────────────────────────────────────────────┤
                    └─────────────────────────────────────────────┘
```

---

## Tabla Comparativa: Tipos de Probe

| Tipo | Proposito | Si falla... | Caso de uso |
|------|-----------|-------------|-------------|
| **Liveness** | Esta vivo el contenedor? | Kubelet reinicia el contenedor | Detectar deadlocks, procesos colgados |
| **Readiness** | Esta listo para trafico? | Se remueve de Endpoints del Service | Carga de cache, conexion a BD |
| **Startup** | Termino de iniciar? | Cuenta como fallo de startup | Apps Java, migraciones de BD, inicio >30s |

---

## Como se configura una probe (para principiantes)

Antes de ejecutar el lab, mira como luce una probe en YAML para que puedas reconocerla cuando la veas:

```yaml
livenessProbe:
  httpGet:
    path: /healthz    # Ruta HTTP que Kubernetes consultara
    port: 8080        # Puerto donde escucha la aplicacion
  initialDelaySeconds: 10   # Esperar 10s antes de la primera verificacion
  periodSeconds: 5          # Verificar cada 5 segundos
  failureThreshold: 3       # Fallar 3 veces antes de reiniciar
  timeoutSeconds: 1         # Esperar maximo 1s la respuesta HTTP
```

**Significado de cada parametro:**

| Parametro | Que controla | Valor tipico |
|-----------|-------------|--------------|
| `initialDelaySeconds` | Cuantos segundos esperar antes de la primera verificacion | 10-30s |
| `periodSeconds` | Cada cuantos segundos repetir la verificacion | 5-10s |
| `failureThreshold` | Cuantos fallos consecutivos antes de actuar | 3 |
| `successThreshold` | Cuantos exitos para considerar que se recupero | 1 (liveness/startup), 1+ (readiness) |
| `timeoutSeconds` | Cuantos segundos esperar la respuesta antes de contar como fallo | 1-3s |

El tiempo maximo que puede tardar en detectar un problema es aproximadamente: `periodSeconds * failureThreshold`.

---

## Paso 0: Preparar Minikube (1 min)

```bash
minikube start

# Verificar
minikube status
kubectl cluster-info
```

---

## Paso 1: Desplegar Todo (1 min)

```bash
kubectl apply -f probes-lab.yaml
```

Verificar:

```bash
# Ver namespace creado
kubectl get ns lab-probes --show-labels

# Ver todos los recursos
kubectl get all -n lab-probes
```

**Salida esperada:** 1 namespace, 2 Pods de liveness, 1 Deployment con 3 replicas, 1 Service, 1 Pod startup, 1 Pod combined, 1 Pod broken, 1 Pod test-tools.

> **Que aprendimos en el Paso 1:** Un solo `kubectl apply -f` puede crear multiples recursos de distintos tipos a la vez. Kubernetes lee el YAML, crea el namespace y luego todos los Pods y Deployments dentro de el. El flag `-n` indica en que namespace buscar los recursos.

---

## Paso 2: Explorar Liveness Probes (3 min)

### Liveness HTTP

```bash
# Ver estado del Pod
kubectl get pod liveness-http -n lab-probes

# Ver configuracion de la probe
kubectl describe pod liveness-http -n lab-probes | grep -A 10 "Liveness:"
```

**Salida esperada:**

```
NAME            READY   STATUS    RESTARTS   AGE
liveness-http   1/1     Running   0          1m
```

### Que significa "exec" en una probe?

Cuando ves `exec` en la configuracion de una probe, significa que Kubernetes ejecuta un comando **dentro del contenedor** (como si entraras con `kubectl exec`) y verifica el codigo de salida:

- **Exit code 0** = el comando tuvo exito = la probe pasa = el contenedor esta sano
- **Exit code distinto de 0** = el comando fallo = la probe falla = kubelet cuenta un fallo

En este lab, el comando es `cat /tmp/healthy`. Si el archivo existe, `cat` retorna exit code 0. Si no existe, retorna exit code 1. El contenedor esta configurado para borrar ese archivo a los 30 segundos, simulando que la aplicacion "se cuelga".

### Liveness Exec (observar reinicio)

```bash
# Esperar ~40s y ver reinicios
kubectl get pod liveness-exec -n lab-probes -w
```

**Salida esperada (tras ~40s):**

```
NAME            READY   STATUS    RESTARTS   AGE
liveness-exec   1/1     Running   0          20s
liveness-exec   1/1     Running   1 (2s ago)   45s
```

**Explicacion:** El archivo `/tmp/healthy` se borra a los 30s. La probe falla 3 veces seguidas (segun `failureThreshold: 3`) → kubelet reinicia el contenedor automaticamente. El contador `RESTARTS` aumenta en 1 cada vez.

```bash
# Ver eventos de la probe
kubectl describe pod liveness-exec -n lab-probes | grep -A 5 "Events:"
```

> **Que aprendimos en el Paso 2:** Una liveness probe puede usar HTTP GET (para aplicaciones web) o exec (para cualquier cosa que pueda verificarse con un comando). Cuando la probe falla repetidamente, kubelet reinicia el contenedor — no el Pod completo, solo el contenedor dentro del Pod. El numero de reinicios se acumula en `RESTARTS`.

---

## Paso 3: Readiness + Service (3 min)

```bash
# Ver Pods Ready
kubectl get pods -n lab-probes -l app=webapp-ready
```

**Salida esperada:**

```
NAME                           READY   STATUS    RESTARTS   AGE
webapp-ready-abc123            1/1     Running   0          2m
webapp-ready-def456            1/1     Running   0          2m
webapp-ready-ghi789            1/1     Running   0          2m
```

```bash
# Ver Endpoints del Service (deben tener IPs)
kubectl get endpoints webapp-ready -n lab-probes
```

**Salida esperada:**

```
NAME           ENDPOINTS                                   AGE
webapp-ready   10.244.0.5:80,10.244.0.6:80,10.244.0.7:80  2m
```

```bash
# Probar conectividad desde test-tools
kubectl exec test-tools -n lab-probes -- wget -qO- http://webapp-ready.lab-probes.svc.cluster.local
```

**Pregunta:** Si un Pod falla la readinessProbe, que pasa con sus Endpoints?

Se remueve del Service. El trafico se redistribuye a los Pods restantes. El Pod no se reinicia (sigue vivo), simplemente deja de recibir trafico nuevo hasta que vuelva a pasar la readiness probe.

> **Que aprendimos en el Paso 3:** La readinessProbe es la que controla si un Pod aparece en los Endpoints de un Service. Si hay 3 replicas y una falla la readiness, el Service solo envia trafico a las 2 restantes. Esto es fundamental para hacer deploys sin downtime (zero-downtime deployments).

---

## Paso 4: Startup Probe (2 min)

```bash
# Ver estado del Pod
kubectl get pod slow-startup-app -n lab-probes

# Ver secuencia de probes
kubectl describe pod slow-startup-app -n lab-probes | grep -E "(startup|liveness|readiness)" -i
```

**Salida esperada:**

```
    Startup:        http-get http://:80/ delay=0s timeout=1s period=2s #success=1 #failure=15
    Liveness:       http-get http://:80/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Readiness:      http-get http://:80/ delay=0s timeout=1s period=5s #success=1 #failure=1
```

**Flujo:** `startupProbe` pasa primero → kubelet activa `livenessProbe` y `readinessProbe`.

La ventana maxima de arranque para `slow-startup-app` es: `periodSeconds (2) * failureThreshold (15) = 30 segundos`. Si la app no arranca en 30 segundos, Kubernetes considera que fallo el arranque y reinicia el contenedor.

> **Que aprendimos en el Paso 4:** La startup probe resuelve el dilema "necesito tiempo para arrancar, pero no quiero que Kubernetes me mate durante el arranque". Calcula la ventana como `periodSeconds * failureThreshold`. Para apps lentas (Java, apps con migraciones de BD), esta probe es indispensable.

---

## Paso 5: Probes Combinadas - Patron Produccion (2 min)

```bash
# Ver Pod con las 3 probes
kubectl describe pod combined-probes -n lab-probes | grep -A 3 "Startup:\|Liveness:\|Readiness:"
```

**Salida esperada:**

```
    Startup:    http-get http://:80/ delay=0s timeout=1s period=2s #success=1 #failure=10
    Liveness:   http-get http://:80/ delay=0s timeout=3s period=10s #success=1 #failure=3
    Readiness:  http-get http://:80/ delay=0s timeout=1s period=5s #success=1 #failure=3
```

**Patron recomendado para produccion:**

```
startup → Tiempo generoso (periodSeconds * failureThreshold = ventana de arranque)
liveness → Menos frecuente, mas tolerante (failureThreshold: 3+, timeoutSeconds: 3+)
readiness → Mas frecuente, detecta rapido cuando no puede servir trafico
```

> **Que aprendimos en el Paso 5:** En produccion siempre se usan las tres probes juntas. Cada una tiene un rol distinto y no se reemplazan entre si. El orden de activacion es siempre: startup primero, luego liveness y readiness en paralelo. Configurar `timeoutSeconds` generoso en liveness evita falsos positivos por picos de carga.

---

## Paso 6: Troubleshooting - Probe Rota (2 min)

### Que es CrashLoopBackOff?

Antes de ver la probe rota, entiende este estado que veras frecuentemente:

**`CrashLoopBackOff`** significa que el contenedor falla repetidamente y Kubernetes esta aumentando el tiempo de espera entre reinicios (backoff exponencial: 10s, 20s, 40s, 80s... hasta 5 minutos).

- **"Crash"**: el contenedor termino con error (exit code != 0) o fue reiniciado por una liveness probe fallida
- **"Loop"**: esto ocurre en ciclo, una y otra vez
- **"BackOff"**: Kubernetes espera cada vez mas tiempo entre reinicios para no desperdiciar recursos

El estado `CrashLoopBackOff` no es un estado final permanente — Kubernetes seguira intentando reiniciar el contenedor indefinidamente, con pausas cada vez mas largas. Para diagnosticar la causa real, usa `kubectl describe` y `kubectl logs --previous`.

```bash
# Ver Pod en CrashLoopBackOff
kubectl get pod broken-probe -n lab-probes
```

**Salida esperada (tras ~30s):**

```
NAME           READY   STATUS             RESTARTS   AGE
broken-probe   0/1     CrashLoopBackOff   3          1m
```

```bash
# Diagnosticar con describe
kubectl describe pod broken-probe -n lab-probes | tail -15
```

**Salida esperada en Events:**

```
Warning  Unhealthy  kubelet  Liveness probe failed: HTTP probe failed with statuscode: 404
Normal   Killing    kubelet  Container app failed liveness probe, will be restarted
```

**Como leer la seccion Events de `kubectl describe`:**

La seccion Events es la bitacora de lo que Kubernetes hizo con este Pod. Cada linea tiene estos campos:

| Campo | Significado |
|-------|-------------|
| `Warning` o `Normal` | Severidad del evento. Warning indica un problema. |
| `Unhealthy` | El tipo de evento. "Unhealthy" aparece cuando una probe falla. |
| `Killing` | Kubernetes va a matar (reiniciar) el contenedor. |
| `kubelet` | El componente que genero el evento (el agente del nodo). |
| El mensaje al final | Descripcion detallada: que probe fallo, con que error, y que accion se tomara. |

Cuando ves `Liveness probe failed: HTTP probe failed with statuscode: 404`, significa que Kubernetes hizo un HTTP GET al path configurado y el servidor respondio con codigo 404 (Not Found). Cualquier codigo fuera del rango 200-399 se considera un fallo.

```bash
# Ver logs del contenedor anterior
kubectl logs broken-probe -n lab-probes --previous 2>/dev/null

# Probar la probe manualmente (si el Pod esta Running)
kubectl exec broken-probe -n lab-probes -- wget -qO- http://localhost/nonexistent 2>&1 || echo "404 - Ruta no existe"
```

**Diagnostico:** La livenessProbe apunta a `/nonexistent` que retorna 404. Solucion: cambiar path a `/`.

> **Que aprendimos en el Paso 6:** El flujo de diagnostico para un Pod en CrashLoopBackOff es siempre: (1) `kubectl get pod` para confirmar el estado, (2) `kubectl describe pod` para leer los Events y saber que fallo, (3) `kubectl logs --previous` para ver los logs del contenedor antes de que muriera. La causa mas comun de CrashLoopBackOff en produccion es una probe mal configurada o una aplicacion que no responde en el path/puerto correcto.

---

## Paso 7: Limpiar (1 min)

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete namespace lab-probes
kubectl config set-context --current --namespace=default
```

---

## Resumen Visual

```
┌─────────────────────────────────────────────────┐
│  STARTUP PROBE                                  │
│  - Se ejecuta primero al crear el contenedor    │
│  - Mientras no pase, liveness/readiness OFF     │
│  - Ventana: periodSeconds * failureThreshold    │
└────────────────────┬────────────────────────────┘
                     │ (pasa)
                     ▼
┌─────────────────────────────────────────────────┐
│  LIVENESS PROBE                                 │
│  - Verifica que el contenedor esta vivo         │
│  - Si falla → kubelet reinicia el contenedor    │
│  - Para detectar: deadlocks, crashes, bloqueos  │
└────────────────────┬────────────────────────────┘
                     │ (en paralelo)
                     ▼
┌─────────────────────────────────────────────────┐
│  READINESS PROBE                                │
│  - Verifica que puede recibir trafico           │
│  - Si falla → removido de Endpoints del Service │
│  - Para detectar: BD no lista, cache frio       │
└─────────────────────────────────────────────────┘
```

---

## Regla de Oro para principiantes

Cuando no sabes que probe usar, hazte estas tres preguntas:

1. **"Si mi contenedor se cuelga internamente, quiero que Kubernetes lo reinicie automaticamente?"**
   Si la respuesta es SI → configura una `livenessProbe`.

2. **"Mi aplicacion tarda en arrancar y no quiero que Kubernetes la mate durante ese tiempo?"**
   Si la respuesta es SI → configura una `startupProbe` con ventana generosa.

3. **"Quiero que el Service no envie trafico a mi contenedor hasta que este completamente listo?"**
   Si la respuesta es SI → configura una `readinessProbe`.

En produccion, la respuesta a las tres preguntas es casi siempre SI. Por eso se usan las tres juntas, como viste en el Pod `combined-probes` de este lab.
