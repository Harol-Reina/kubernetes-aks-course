# Laboratorio 03: Troubleshooting de Health Checks

**Duracion estimada:** 45 minutos
**Nivel:** Intermedio
**Objetivo:** Diagnosticar y resolver problemas comunes con probes usando herramientas de debugging de Kubernetes

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **Diagnostico CrashLoopBackOff** | Identificar reinicios causados por livenessProbe fallida. Usar `kubectl describe` y `kubectl logs --previous` |
| **Label selector mismatch** | Detectar cuando el selector del Service no coincide con las labels de los Pods, causando Endpoints vacios |
| **Ajuste de timeouts** | Calibrar `timeoutSeconds`, `periodSeconds` y `failureThreshold` para evitar falsos positivos bajo carga |
| **Cascading failures** | Entender como probes agresivas pueden reiniciar multiples Pods en cadena y saturar el cluster |
| **Debugging manual de probes** | Usar `kubectl exec` para ejecutar probes manualmente y aislar el origen del fallo |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las operaciones se realizan mediante archivos YAML:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `crashloop-pod.yaml` | 1 | Pod con livenessProbe rota que causa CrashLoopBackOff |
| `webapp-no-traffic.yaml` | 2 | Deployment + Service con selector incompleto (Endpoints vacios) |
| `buggy-app.yaml` | Final | Deployment con 3 errores de probes para diagnosticar y corregir |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |

---

## Requisitos Previos

- Cluster de Kubernetes funcional (Minikube, kind, k3s o cloud)
- `kubectl` configurado
- Lab 01 y Lab 02 completados (conceptos de liveness, readiness, startup)

> Este laboratorio funciona con la configuracion por defecto de Minikube.

### Verificacion del entorno

```bash
kubectl cluster-info
kubectl get nodes
kubectl auth can-i create pods
kubectl auth can-i create deployments

# Verificar archivos YAML del laboratorio
ls -la *.yaml
```

---

## Problema 1: CrashLoopBackOff

### Escenario

Revisa el archivo `crashloop-pod.yaml` antes de aplicarlo:

```bash
cat crashloop-pod.yaml
```

Puntos clave del manifiesto:
- La `livenessProbe` apunta a `/nonexistent` (nginx retorna 404)
- `failureThreshold: 1` significa que un solo fallo reinicia el contenedor
- `periodSeconds: 2` verifica cada 2 segundos

```bash
kubectl apply -f crashloop-pod.yaml
kubectl get pods crashloop-pod -w
```

### Diagnostico

```bash
# 1. Ver estado
kubectl get pod crashloop-pod

# Output:
# NAME            READY   STATUS             RESTARTS   AGE
# crashloop-pod   0/1     CrashLoopBackOff   5          5m

# 2. Ver eventos
kubectl describe pod crashloop-pod | tail -30

# 3. Ver logs
kubectl logs crashloop-pod
kubectl logs crashloop-pod --previous  # Logs del contenedor anterior
```

### Solucion

```yaml
# Corregido
livenessProbe:
  httpGet:
    path: /              # Ruta valida
    port: 80
  initialDelaySeconds: 10  # Mas tiempo
  periodSeconds: 10
  failureThreshold: 3      # Tolerante
```

---

## Problema 2: Pod Ready pero Sin Trafico

### Escenario

Revisa el archivo `webapp-no-traffic.yaml`:

```bash
cat webapp-no-traffic.yaml
```

Puntos clave:
- El Deployment define Pods con labels `app: webapp` Y `tier: frontend`
- El Service solo tiene `app: webapp` en su selector (falta `tier: frontend`)
- La readinessProbe es correcta: los Pods pasan a Ready normalmente

```bash
kubectl apply -f webapp-no-traffic.yaml
```

### Diagnostico

```bash
# 1. Pods estan Ready
kubectl get pods -l app=webapp
# NAME                    READY   STATUS
# webapp-no-traffic-xxx   1/1     Running

# 2. PERO no hay endpoints
kubectl get endpoints webapp-service
# NAME              ENDPOINTS   AGE
# webapp-service    <none>      1m

# 3. Comparar labels
kubectl get pods -l app=webapp --show-labels
kubectl get service webapp-service -o yaml | grep selector -A5
```

### Solucion

Agregar el label faltante al Service:

```yaml
spec:
  selector:
    app: webapp
    tier: frontend  # Agregar para coincidir con los Pods
```

---

## Problema 3: Timeouts de Probes

### Escenario

Este problema es ilustrativo: simula una aplicacion que responde lento bajo carga.

```bash
# En un cluster real, veriamos esto en los eventos:
kubectl describe pod slow-app

# Events:
# Warning Unhealthy  1m  kubelet  Readiness probe failed: Get "http://10.244.0.5:8080/ready": context deadline exceeded
```

### Diagnostico

```bash
# 1. Probar manualmente el endpoint
kubectl exec slow-app -- time wget -O- http://localhost:8080/ready

# Si tarda > timeoutSeconds, fallara

# 2. Ver configuracion actual
kubectl get pod slow-app -o yaml | grep -A10 readinessProbe
```

### Solucion

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  timeoutSeconds: 5      # Incrementar de 1s a 5s
  periodSeconds: 10      # Menos frecuente
  failureThreshold: 3
```

---

## Problema 4: Liveness Mata Pods bajo Carga

### Escenario

Durante picos de trafico, los Pods se reinician constantemente.

### Diagnostico

```bash
# Ver metricas de CPU/Memoria (requiere metrics-server)
kubectl top pods

# Ver eventos
kubectl get events --sort-by='.lastTimestamp' | grep Unhealthy

# Ver configuracion de probes
kubectl get pod <pod-name> -o yaml | grep -A15 livenessProbe
```

### Analisis

```yaml
# Problema: Muy agresiva
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 5
  failureThreshold: 1    # Un fallo = muerte
  timeoutSeconds: 1      # 1s no es suficiente bajo carga
```

### Solucion

```yaml
# Tolerante
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 10
  failureThreshold: 5    # Permite fallos transitorios
  timeoutSeconds: 5

  # Y/O incrementar recursos
  resources:
    requests:
      cpu: "200m"        # Mas CPU
      memory: "256Mi"
```

---

## Comandos Utiles de Debugging

### Ver Estado de Probes

```bash
# Eventos de probes
kubectl get events --field-selector involvedObject.name=<pod-name>,reason=Unhealthy

# Configuracion completa
kubectl get pod <pod-name> -o yaml

# Solo seccion de probes
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].livenessProbe}'
```

### Ejecutar Probes Manualmente

```bash
# HTTP Probe
kubectl exec <pod-name> -- wget -O- http://localhost:8080/health

# TCP Probe
kubectl exec <pod-name> -- nc -zv localhost 8080

# Exec Probe
kubectl exec <pod-name> -- cat /tmp/healthy
```

### Monitoreo en Tiempo Real

```bash
# Watch Pods
kubectl get pods -w

# Watch Events
kubectl get events --watch | grep probe

# Logs con timestamps
kubectl logs <pod-name> -f --timestamps
```

---

## Ejercicio Final: Debugging Completo

### Desplegar App Problematica

Revisa el archivo `buggy-app.yaml`:

```bash
cat buggy-app.yaml
```

El manifiesto contiene tres errores deliberados. Tu tarea es identificarlos y corregirlos.

```bash
kubectl apply -f buggy-app.yaml
kubectl get pods -l app=buggy -w
```

### Tarea

1. Aplica el Deployment
2. Identifica todos los problemas con `kubectl describe` y `kubectl get events`
3. Corrige la configuracion en `buggy-app.yaml`
4. Vuelve a aplicar y verifica que funcione correctamente

<details>
<summary>Solucion</summary>

**Problemas encontrados**:
1. Liveness path `/healthz` no existe → Cambiar a `/`
2. Readiness port `8080` incorrecto → Cambiar a `80`
3. Liveness muy agresiva (`failureThreshold: 2`, `timeout: 1s`)

**Configuracion corregida**:

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 80
  periodSeconds: 10
  failureThreshold: 3
  timeoutSeconds: 3

readinessProbe:
  httpGet:
    path: /
    port: 80
  periodSeconds: 5
  failureThreshold: 3
```

</details>

---

## Checklist de Troubleshooting

Cuando una probe falla, verifica:

```
[ ] El path/puerto es correcto?
[ ] initialDelaySeconds es suficiente?
[ ] timeoutSeconds es realista?
[ ] failureThreshold es tolerante?
[ ] La aplicacion realmente responde?
[ ] Hay recursos (CPU/memoria) suficientes?
[ ] Los labels del Service coinciden con los Pods?
[ ] La probe se puede ejecutar manualmente con exito?
```

---

## Limpieza

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete pod crashloop-pod
kubectl delete deployment webapp-no-traffic buggy-app
kubectl delete service webapp-service
```

---

## Resumen

Al completar este laboratorio has practicado:

- Diagnosticar CrashLoopBackOff causado por probes con ruta invalida
- Resolver Endpoints vacios por label selector mismatch
- Ajustar timeouts y thresholds para evitar falsos positivos
- Prevenir cascading failures con configuracion tolerante
- Usar herramientas de debugging efectivamente

## Has Completado el Modulo!

Felicitaciones! Ahora dominas Health Checks en Kubernetes.

## Recursos Adicionales

- **[README del Modulo](../../README.md)**
- **[Ejemplos Completos](../../ejemplos/README.md)**
- **[Kubernetes Docs - Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)**
