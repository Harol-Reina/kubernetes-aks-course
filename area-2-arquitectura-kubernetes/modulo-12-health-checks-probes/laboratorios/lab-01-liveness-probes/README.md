# Laboratorio 01: Liveness y Readiness Probes

**Duracion estimada:** 45 minutos
**Nivel:** Basico
**Objetivo:** Configurar Liveness y Readiness Probes, entender la diferencia entre ambas, y diagnosticar problemas comunes con health checks

---

## Tecnicas y Conceptos Utilizados

| Tecnica | Descripcion |
|---------|-------------|
| **Liveness Probe HTTP** | Verificacion periodica via HTTP GET. Si retorna status >= 400, Kubernetes reinicia el contenedor |
| **Liveness Probe Exec** | Ejecuta un comando dentro del contenedor. Exit code 0 = exito, otro valor = fallo y reinicio |
| **Readiness Probe** | Controla si el Pod recibe trafico del Service. Si falla, el Pod se remueve de Endpoints pero NO se reinicia |
| **failureThreshold** | Numero de fallos consecutivos antes de tomar accion (reinicio o exclusion de trafico) |
| **initialDelaySeconds** | Tiempo de espera antes de la primera verificacion, permitiendo que la app arranque |
| **Probes combinadas** | Usar Liveness + Readiness juntas: liveness detecta procesos muertos, readiness controla trafico |
| **CrashLoopBackOff** | Estado que indica reinicios continuos. Frecuentemente causado por probes mal configuradas |

---

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las operaciones se realizan mediante archivos YAML:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `liveness-http.yaml` | 1 | Pod con Liveness Probe HTTP usando agnhost que simula fallos despues de 10s |
| `liveness-exec.yaml` | 2 | Pod con Liveness Probe Exec que verifica existencia de archivo /tmp/healthy |
| `readiness-deployment.yaml` | 3 | Deployment 3 replicas con Readiness + Liveness para control de trafico |
| `combined-probes.yaml` | 4 | Pod con Liveness (exec/pidof) y Readiness (httpGet) combinadas |
| `broken-liveness.yaml` | 5 | Pod con probe rota para practicar troubleshooting de CrashLoopBackOff |

**Scripts auxiliares:**

| Archivo | Descripcion |
|---------|-------------|
| `cleanup.sh` | Script de limpieza de todos los recursos del laboratorio |

---

## Requisitos Previos

- Cluster de Kubernetes funcional (Minikube, kind, AKS, etc.)
- `kubectl` configurado
- Conocimientos de Pods y Services

> Este laboratorio funciona con la configuracion por defecto de Minikube.

### Verificacion del entorno

```bash
kubectl cluster-info
kubectl get nodes
kubectl auth can-i create pods

# Verificar archivos YAML del laboratorio
ls -la *.yaml
```

---

## Parte 1: Liveness Probe con HTTP

### Paso 1.1: Crear Pod con Liveness Probe

Revisa el archivo `liveness-http.yaml` antes de aplicarlo:

```bash
cat liveness-http.yaml
```

Puntos clave del manifiesto:
- Imagen `agnhost:2.40` con argumento `liveness` simula una app que falla despues de 10s
- `livenessProbe.httpGet` verifica `/healthz` en puerto 8080
- `failureThreshold: 3` con `periodSeconds: 3` = reinicio tras ~9s de fallos

```bash
kubectl apply -f liveness-http.yaml
```

### Paso 1.2: Observar el Comportamiento

```bash
# Ver el Pod iniciando
kubectl get pods liveness-http -w

# En otra terminal, ver eventos
kubectl describe pod liveness-http

# Ver logs de la aplicacion
kubectl logs liveness-http -f
```

**Pregunta**: Que observas despues de ~30-40 segundos?

<details>
<summary>Respuesta</summary>

El Pod empieza a reiniciarse. Esto es porque la imagen `agnhost:2.40` con el argumento `liveness` simula una aplicacion que:
- Primeros 10 segundos: Devuelve `200 OK`
- Despues de 10 segundos: Devuelve `500 Internal Server Error`

Kubernetes detecta 3 fallos consecutivos (failureThreshold: 3) y reinicia el contenedor.

</details>

### Paso 1.3: Verificar Reinicios

```bash
# Ver conteo de reinicios
kubectl get pod liveness-http
```

**Salida esperada:**

```
NAME            READY   STATUS    RESTARTS   AGE
liveness-http   1/1     Running   2          2m
```

El campo `RESTARTS` incrementa cada vez que la Liveness Probe falla.

### Paso 1.4: Ver Eventos Detallados

```bash
kubectl describe pod liveness-http | grep -A15 "Events:"
```

Busca lineas como:

```
Warning  Unhealthy  1m (x6 over 3m)  kubelet  Liveness probe failed: HTTP probe failed with statuscode: 500
Normal   Killing    1m (x3 over 3m)  kubelet  Container webapp failed liveness probe, will be restarted
```

---

## Parte 2: Liveness Probe con Exec

### Paso 2.1: Crear Pod con Exec Probe

Revisa el archivo `liveness-exec.yaml`:

```bash
cat liveness-exec.yaml
```

Puntos clave:
- El contenedor crea `/tmp/healthy` al inicio y lo elimina despues de 30s
- La probe ejecuta `cat /tmp/healthy` cada 5s
- Cuando el archivo no existe, la probe falla (exit code 1)

```bash
kubectl apply -f liveness-exec.yaml
kubectl get pods liveness-exec -w
```

### Paso 2.2: Entender el Flujo

```
Segundo 0-30:  Archivo /tmp/healthy existe
               cat /tmp/healthy -> Exit 0 -> Probe OK

Segundo 30:    rm -f /tmp/healthy (archivo eliminado)

Segundo 35:    cat /tmp/healthy -> Exit 1 (archivo no existe) -> Probe FALLA
Segundo 40:    cat /tmp/healthy -> Exit 1 -> Probe FALLA (2do fallo)
Segundo 45:    cat /tmp/healthy -> Exit 1 -> Probe FALLA (3er fallo)

               -> Kubernetes REINICIA el contenedor
```

### Paso 2.3: Experimento Manual

```bash
# Ejecutar el comando de la probe manualmente
kubectl exec liveness-exec -- cat /tmp/healthy

# Si el Pod aun no se reinicio, veras el contenido
# Si ya pasaron 30s, veras un error
```

---

## Parte 3: Readiness Probe y Services

### Paso 3.1: Crear Deployment con Readiness

Revisa el archivo `readiness-deployment.yaml`:

```bash
cat readiness-deployment.yaml
```

Puntos clave:
- 3 replicas de nginx con Readiness + Liveness Probes
- Readiness verifica en named port `http`
- `successThreshold: 1` para marcar Ready rapidamente

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
```

**Salida esperada (3 IPs, una por cada Pod):**

```
NAME               ENDPOINTS                           AGE
webapp-readiness   10.244.0.5:80,10.244.0.6:80,...    1m
```

### Paso 3.4: Simular Fallo de Readiness

```bash
# Obtener el nombre de un Pod
POD_NAME=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}')

# Ejecutar dentro del Pod para simular que no esta listo
kubectl exec $POD_NAME -- sh -c 'rm /usr/share/nginx/html/index.html'

# Observar como la readiness probe falla
kubectl describe pod $POD_NAME | grep -A5 "Readiness"

# Ver endpoints (el Pod fallido NO aparecera)
kubectl get endpoints webapp-readiness
```

**Clave**: El Pod sigue corriendo, pero ya no recibe trafico del Service.

### Paso 3.5: Restaurar el Pod

```bash
# Restaurar el archivo index.html
kubectl exec $POD_NAME -- sh -c 'echo "OK" > /usr/share/nginx/html/index.html'

# El Pod vuelve a ser Ready
kubectl get pods -l app=webapp
kubectl get endpoints webapp-readiness
```

---

## Parte 4: Liveness vs Readiness - Comparacion

### Ejercicio: Configuracion Combinada

Revisa el archivo `combined-probes.yaml`:

```bash
cat combined-probes.yaml
```

Puntos clave:
- **Liveness (exec)**: verifica que el proceso nginx este vivo con `pidof nginx`
- **Readiness (httpGet)**: verifica que el servidor responda en puerto 80
- Permite experimentar con dos escenarios diferentes

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

**Resultado**: Pod se REINICIA (Liveness fallo)

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

Revisa el archivo `broken-liveness.yaml`:

```bash
cat broken-liveness.yaml
```

El manifiesto tiene una probe intencionalmente rota:
- Ruta `/nonexistent` que nginx no sirve
- `failureThreshold: 1` (un solo fallo = reinicio)
- `periodSeconds: 2` (verificacion muy frecuente)

```bash
kubectl apply -f broken-liveness.yaml
kubectl get pods broken-liveness -w
```

**Pregunta**: Que observas?

<details>
<summary>Respuesta</summary>

El Pod entra en `CrashLoopBackOff` porque:
1. Liveness probe falla (ruta `/nonexistent` no existe)
2. `failureThreshold: 1` = Un solo fallo reinicia el Pod
3. `periodSeconds: 2` = Verifica muy frecuentemente
4. Ciclo infinito de reinicio

**Solucion**: Incrementar `failureThreshold` y `initialDelaySeconds`

</details>

### Problema 2: Pod Ready pero sin Trafico

```bash
# Verificar que el Pod este Ready
kubectl get pods combined-test

# Verificar endpoints del Service
kubectl get endpoints combined-test

# Si el Pod esta Ready pero no aparece en endpoints:
# - Verificar labels (selector del Service)
kubectl get pod combined-test --show-labels
kubectl get service combined-test -o yaml | grep selector -A3
```

---

## Parte 6: Preguntas de Repaso

### Pregunta 1

Que pasa si un Pod tiene Liveness Probe pero NO tiene Readiness Probe?

<details>
<summary>Respuesta</summary>

El Pod:
- Se reiniciara si Liveness falla
- Se marcara como Ready inmediatamente al iniciar (sin verificacion)
- Recibira trafico desde el primer momento (puede ser prematuro)

</details>

### Pregunta 2

Que valores de `failureThreshold` y `periodSeconds` dan un tiempo de tolerancia de 30 segundos?

<details>
<summary>Respuesta</summary>

Opciones validas:
- `periodSeconds: 10`, `failureThreshold: 3` -> 30s
- `periodSeconds: 5`, `failureThreshold: 6` -> 30s
- `periodSeconds: 15`, `failureThreshold: 2` -> 30s

Formula: Tiempo total = `periodSeconds x failureThreshold`

</details>

### Pregunta 3

En que situacion usarias Liveness Probe con `exec` en lugar de `httpGet`?

<details>
<summary>Respuesta</summary>

Usa `exec` cuando:
- La aplicacion no tiene endpoint HTTP
- Necesitas verificar multiples condiciones
- Aplicacion legacy sin instrumentacion
- Verificacion de archivos o procesos del sistema

</details>

---

## Limpieza

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete pod liveness-http liveness-exec combined-test broken-liveness
kubectl delete deployment webapp-readiness
kubectl delete service webapp-readiness combined-test
```

---

## Resumen

Al completar este laboratorio has practicado:

- Configurar Liveness Probe (HTTP y exec)
- Configurar Readiness Probe y su efecto en Services/Endpoints
- Combinar Liveness y Readiness en un mismo Pod
- Diagnosticar CrashLoopBackOff causado por probes mal configuradas
- Entender cuando un Pod se reinicia vs cuando se quita del trafico

## Siguiente Laboratorio

Continua con:
- **[Laboratorio 02 - Startup Probes y Casos Avanzados](../lab-02-readiness-probes/)**

## Recursos

- **[README del Modulo](../../README.md)**: Teoria completa
- **[Ejemplos](../../ejemplos/README.md)**: Mas ejemplos de probes
