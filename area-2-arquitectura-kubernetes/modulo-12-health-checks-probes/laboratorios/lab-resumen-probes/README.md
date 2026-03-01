# Resumen Practico: Health Checks y Probes

**Duracion:** 15 minutos | **Nivel:** Repaso integral | **Archivo:** `probes-lab.yaml`

Un solo YAML despliega Pods con livenessProbe (HTTP y exec), un Deployment con readinessProbe y Service, un Pod con startupProbe, probes combinadas (patron produccion), y un Pod con probe rota para troubleshooting, usando Minikube.

---

## Que son los Health Checks

Los **Health Checks** en Kubernetes usan tres tipos de probes para monitorear contenedores:

- **Liveness Probe**: Verifica si el contenedor esta vivo. Si falla, kubelet lo reinicia.
- **Readiness Probe**: Verifica si el contenedor esta listo para recibir trafico. Si falla, se remueve de los Endpoints del Service.
- **Startup Probe**: Protege apps con inicio lento. Mientras no pase, liveness y readiness estan deshabilitadas.

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

**Explicacion:** El archivo `/tmp/healthy` se borra a los 30s. La probe falla 3 veces → reinicio automatico.

```bash
# Ver eventos de la probe
kubectl describe pod liveness-exec -n lab-probes | grep -A 5 "Events:"
```

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

Se remueve del Service. El trafico se redistribuye a los Pods restantes.

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

---

## Paso 6: Troubleshooting - Probe Rota (2 min)

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

```bash
# Ver logs del contenedor anterior
kubectl logs broken-probe -n lab-probes --previous 2>/dev/null

# Probar la probe manualmente (si el Pod esta Running)
kubectl exec broken-probe -n lab-probes -- wget -qO- http://localhost/nonexistent 2>&1 || echo "404 - Ruta no existe"
```

**Diagnostico:** La livenessProbe apunta a `/nonexistent` que retorna 404. Solucion: cambiar path a `/`.

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
