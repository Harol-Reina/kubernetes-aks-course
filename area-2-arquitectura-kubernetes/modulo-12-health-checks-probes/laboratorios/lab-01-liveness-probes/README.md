# Laboratorio 1: Health Checks Básicos - Liveness y Readiness Probes

## Objetivos

Al finalizar este laboratorio, podrás:

✅ Configurar Liveness Probes para detectar contenedores fallidos  
✅ Configurar Readiness Probes para controlar tráfico  
✅ Entender la diferencia entre Liveness y Readiness  
✅ Diagnosticar problemas con health checks

**Duración estimada**: 45 minutos

---

## Requisitos Previos

- Cluster de Kubernetes funcionando (minikube, kind, AKS, etc.)
- `kubectl` configurado
- Conocimientos de Pods y Services

```bash
# Verificar cluster
kubectl cluster-info
kubectl get nodes
```

---

## Parte 1: Liveness Probe con HTTP

### Paso 1.1: Crear Pod con Liveness Probe

Crea un archivo `liveness-http.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-http
  labels:
    app: demo
spec:
  containers:
  - name: webapp
    image: registry.k8s.io/e2e-test-images/agnhost:2.40
    args:
    - liveness
    ports:
    - containerPort: 8080
    
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 3
      periodSeconds: 3
      failureThreshold: 3
```

Aplica el manifiesto:

```bash
kubectl apply -f liveness-http.yaml
```

### Paso 1.2: Observar el Comportamiento

```bash
# Ver el Pod iniciando
kubectl get pods liveness-http -w

# En otra terminal, ver eventos
kubectl describe pod liveness-http

# Ver logs de la aplicación
kubectl logs liveness-http -f
```

**❓ Pregunta**: ¿Qué observas después de ~30-40 segundos?

<details>
<summary>💡 Respuesta</summary>

El Pod empieza a reiniciarse. Esto es porque la imagen `agnhost:2.40` con el argumento `liveness` simula una aplicación que:
- Primeros 10 segundos: Devuelve `200 OK`
- Después de 10 segundos: Devuelve `500 Internal Server Error`

Kubernetes detecta 3 fallos consecutivos (failureThreshold: 3) y reinicia el contenedor.

</details>

### Paso 1.3: Verificar Reinicios

```bash
# Ver conteo de reinicios
kubectl get pod liveness-http

# Salida esperada:
# NAME            READY   STATUS    RESTARTS   AGE
# liveness-http   1/1     Running   2          2m
```

El campo `RESTARTS` incrementa cada vez que la Liveness Probe falla.

### Paso 1.4: Ver Eventos Detallados

```bash
kubectl describe pod liveness-http | grep -A15 "Events:"
```

Busca líneas como:

```
Warning  Unhealthy  1m (x6 over 3m)  kubelet  Liveness probe failed: HTTP probe failed with statuscode: 500
Normal   Killing    1m (x3 over 3m)  kubelet  Container webapp failed liveness probe, will be restarted
```

---

## Parte 2: Liveness Probe con Exec

### Paso 2.1: Crear Pod con Exec Probe

Crea `liveness-exec.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-exec
spec:
  containers:
  - name: app
    image: registry.k8s.io/busybox:1.36
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600
    
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```

Aplica y observa:

```bash
kubectl apply -f liveness-exec.yaml
kubectl get pods liveness-exec -w
```

### Paso 2.2: Entender el Flujo

```
Segundo 0-30:  Archivo /tmp/healthy existe
               cat /tmp/healthy → Exit 0 → ✅ Probe OK

Segundo 30:    rm -f /tmp/healthy (archivo eliminado)

Segundo 35:    cat /tmp/healthy → Exit 1 (archivo no existe) → ❌ Probe FALLA
Segundo 40:    cat /tmp/healthy → Exit 1 → ❌ Probe FALLA (2do fallo)
Segundo 45:    cat /tmp/healthy → Exit 1 → ❌ Probe FALLA (3er fallo)
               
               → Kubernetes REINICIA el contenedor
```

### Paso 2.3: Experimento Manual

```bash
# Ejecutar el comando de la probe manualmente
kubectl exec liveness-exec -- cat /tmp/healthy

# Si el Pod aún no se reinició, verás el contenido
# Si ya pasaron 30s, verás un error
```

---

## Parte 3: Readiness Probe y Services

### Paso 3.1: Crear Deployment con Readiness

Crea `readiness-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-readiness
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: app
        image: nginx:1.27-alpine
        ports:
        - name: http
          containerPort: 80
        
        readinessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
          successThreshold: 1
          failureThreshold: 3
        
        livenessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 10
          periodSeconds: 10
```

```bash
kubectl apply -f readiness-deployment.yaml
```

### Paso 3.2: Crear Service

```bash
kubectl expose deployment webapp-readiness --port=80 --type=ClusterIP
```

### Paso 3.3: Verificar Endpoints

```bash
# Ver endpoints del Service
kubectl get endpoints webapp-readiness

# Deberías ver 3 IPs (una por cada Pod)
# NAME               ENDPOINTS                           AGE
# webapp-readiness   10.244.0.5:80,10.244.0.6:80,...    1m
```

### Paso 3.4: Simular Fallo de Readiness

```bash
# Obtén el nombre de un Pod
POD_NAME=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}')

# Ejecuta dentro del Pod para simular que no está listo
kubectl exec $POD_NAME -- sh -c 'rm /usr/share/nginx/html/index.html'

# Observa cómo la readiness probe falla
kubectl describe pod $POD_NAME | grep -A5 "Readiness"

# Ver endpoints (el Pod fallido NO aparecerá)
kubectl get endpoints webapp-readiness
```

**💡 Clave**: El Pod sigue corriendo, pero ya no recibe tráfico del Service.

### Paso 3.5: Restaurar el Pod

```bash
# Restaurar el archivo index.html
kubectl exec $POD_NAME -- sh -c 'echo "OK" > /usr/share/nginx/html/index.html'

# El Pod vuelve a ser Ready
kubectl get pods -l app=webapp
kubectl get endpoints webapp-readiness
```

---

## Parte 4: Liveness vs Readiness - Comparación

### Ejercicio: Configuración Combinada

Crea `combined-probes.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: combined-test
spec:
  containers:
  - name: app
    image: nginx:1.27-alpine
    ports:
    - containerPort: 80
    
    # Liveness: Detecta si el proceso nginx está vivo
    livenessProbe:
      exec:
        command:
        - sh
        - -c
        - 'pidof nginx'
      initialDelaySeconds: 10
      periodSeconds: 10
      failureThreshold: 3
    
    # Readiness: Verifica que el servidor responda
    readinessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 2
```

```bash
kubectl apply -f combined-probes.yaml
kubectl expose pod combined-test --port=80
```

### Experimentos

**Experimento 1: Matar nginx (Liveness falla)**

```bash
kubectl exec combined-test -- pkill nginx

# Observa:
kubectl get pod combined-test -w
kubectl describe pod combined-test | tail -20
```

**Resultado**: Pod se REINICIA (Liveness falló)

---

**Experimento 2: Eliminar index.html (Readiness falla)**

```bash
kubectl exec combined-test -- rm /usr/share/nginx/html/index.html

# Observa:
kubectl get endpoints combined-test
kubectl describe pod combined-test | grep -A5 Readiness
```

**Resultado**: Pod se marca como NOT READY, se quita del Service, pero NO se reinicia

---

## Parte 5: Troubleshooting

### Problema 1: CrashLoopBackOff

Crea este Pod problemático:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: broken-liveness
spec:
  containers:
  - name: app
    image: nginx:1.27-alpine
    
    livenessProbe:
      httpGet:
        path: /nonexistent
        port: 80
      initialDelaySeconds: 1
      periodSeconds: 2
      failureThreshold: 1  # ← MUY AGRESIVO
```

```bash
kubectl apply -f broken-liveness.yaml
kubectl get pods broken-liveness -w
```

**❓ ¿Qué observas?**

<details>
<summary>💡 Respuesta</summary>

El Pod entra en `CrashLoopBackOff` porque:
1. Liveness probe falla (ruta `/nonexistent` no existe)
2. `failureThreshold: 1` = Un solo fallo reinicia el Pod
3. `periodSeconds: 2` = Verifica muy frecuentemente
4. Ciclo infinito de reinicio

**Solución**: Incrementar `failureThreshold` y `initialDelaySeconds`

</details>

### Problema 2: Pod Ready pero sin Tráfico

```bash
# Verificar que el Pod esté Ready
kubectl get pods combined-test

# Verificar endpoints del Service
kubectl get endpoints combined-test

# Si el Pod está Ready pero no aparece en endpoints:
# - Verificar labels (selector del Service)
kubectl get pod combined-test --show-labels
kubectl get service combined-test -o yaml | grep selector -A3
```

---

## Parte 6: Preguntas de Repaso

### Pregunta 1

¿Qué pasa si un Pod tiene Liveness Probe pero NO tiene Readiness Probe?

<details>
<summary>💡 Respuesta</summary>

El Pod:
- Se reiniciará si Liveness falla
- Se marcará como Ready inmediatamente al iniciar (sin verificación)
- Recibirá tráfico desde el primer momento (puede ser prematuro)

</details>

### Pregunta 2

¿Qué valores de `failureThreshold` y `periodSeconds` dan un tiempo de tolerancia de 30 segundos?

<details>
<summary>💡 Respuesta</summary>

Opciones válidas:
- `periodSeconds: 10`, `failureThreshold: 3` → 30s
- `periodSeconds: 5`, `failureThreshold: 6` → 30s
- `periodSeconds: 15`, `failureThreshold: 2` → 30s

Fórmula: Tiempo total = `periodSeconds × failureThreshold`

</details>

### Pregunta 3

¿En qué situación usarías Liveness Probe con `exec` en lugar de `httpGet`?

<details>
<summary>💡 Respuesta</summary>

Usa `exec` cuando:
- La aplicación no tiene endpoint HTTP
- Necesitas verificar múltiples condiciones
- Aplicación legacy sin instrumentación
- Verificación de archivos o procesos del sistema

</details>

---

## Limpieza

```bash
kubectl delete pod liveness-http liveness-exec combined-test broken-liveness
kubectl delete deployment webapp-readiness
kubectl delete service webapp-readiness combined-test
```

---

## Resumen

Has aprendido a:

✅ Configurar Liveness Probe (HTTP, TCP, exec)  
✅ Configurar Readiness Probe  
✅ Entender cuándo se reinicia un Pod vs cuándo se quita del Service  
✅ Diagnosticar problemas con probes  
✅ Combinar Liveness y Readiness

## Siguiente Laboratorio

Continúa con:
- **[Laboratorio 2 - Startup Probes Avanzado](lab-02-startup-avanzado.md)**

## Recursos

- **[README del Módulo](../README.md)**: Teoría completa
- **[Ejemplos](../ejemplos/README.md)**: Más ejemplos de probes
