# Laboratorio 4: Estrategia Recreate

## Informacion del Laboratorio

- **Duracion estimada**: 50 minutos
- **Nivel**: Intermedio
- **Requisitos**: Laboratorios 01, 02 y 03 completados
- **Namespace**: `lab-recreate`

## Objetivos

Al completar este laboratorio, seras capaz de:

1. Configurar un Deployment con estrategia `Recreate` correctamente
2. Observar el proceso de downtime completo durante un update con Recreate
3. Comparar el comportamiento de Recreate frente a RollingUpdate en tiempo real
4. Identificar los casos de uso donde Recreate es la estrategia correcta
5. Monitorear eventos y rollout status durante una actualizacion con Recreate
6. Analizar el historial de revisiones despues de aplicar cambios con Recreate

## Prerrequisitos

- Laboratorios 01, 02 y 03 completados
- Conocimiento de Deployments y ReplicaSets
- Cluster de Kubernetes funcional

## Concepto: Estrategia Recreate

La estrategia `Recreate` es la mas simple de las dos estrategias de actualizacion de Kubernetes.
Su comportamiento es:

1. **Escala a cero**: Kubernetes elimina **todos** los Pods del ReplicaSet antiguo simultaneamente
2. **Espera vaciado**: Aguarda a que todos los Pods antiguo terminen completamente
3. **Crea nuevos**: Recien cuando no queda ningun Pod viejo, crea todos los Pods nuevos

Esto produce un **periodo de downtime** entre el paso 1 y el paso 3 en que la aplicacion no
esta disponible para ninguna solicitud.

### Cuando usar Recreate

| Situacion | Justificacion |
|-----------|---------------|
| La aplicacion no soporta multiples versiones en paralelo | Recreate garantiza que solo corra una version |
| Migracion de base de datos incompatible | La nueva version requiere un schema distinto |
| Cambio de volume o almacenamiento exclusivo | Solo un Pod puede montar el volumen a la vez |
| Entornos de desarrollo o testing | El downtime es aceptable y no afecta usuarios reales |
| Recursos limitados | No hay capacidad para correr versiones antigua y nueva en paralelo |

### Cuando NO usar Recreate

- En produccion con usuarios activos donde el downtime no es aceptable
- Cuando puedes hacer rolling updates sin conflictos de version
- En aplicaciones stateless que soportan multiples versiones simultaneas

### Diferencia visual frente a RollingUpdate

```
Recreate:
  t=0   [Pod-v1] [Pod-v1] [Pod-v1]   <- 3 Pods corriendo
  t=5   [------] [------] [------]   <- DOWNTIME: 0 Pods disponibles
  t=10  [Pod-v2] [Pod-v2] [Pod-v2]   <- 3 Pods nuevos corriendo

RollingUpdate:
  t=0   [Pod-v1] [Pod-v1] [Pod-v1]   <- 3 Pods corriendo
  t=5   [Pod-v2] [Pod-v1] [Pod-v1]   <- 1 nuevo + 2 viejos (sin downtime)
  t=10  [Pod-v2] [Pod-v2] [Pod-v1]   <- 2 nuevos + 1 viejo
  t=15  [Pod-v2] [Pod-v2] [Pod-v2]   <- 3 Pods nuevos corriendo
```

## Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las operaciones se realizan mediante archivos YAML:

| Archivo | Ejercicio | Descripcion |
|---------|-----------|-------------|
| `recreate-v1.yaml` | 1 | Deployment inicial con Recreate (nginx:1.19) |
| `recreate-v2.yaml` | 1 | Actualizacion a nginx:1.20 via Recreate |
| `rolling-compare-v1.yaml` | 2 | Deployment comparativo con RollingUpdate (nginx:1.19) |
| `rolling-compare-v2.yaml` | 2 | Actualizacion RollingUpdate a nginx:1.20 |

## Preparacion del Entorno

```bash
# Crear namespace
kubectl create namespace lab-recreate
kubectl config set-context --current --namespace=lab-recreate

# Verificar
kubectl config view --minify | grep namespace:
```

**Output esperado**:
```
    namespace: lab-recreate
```

---

## Ejercicio 1: Recreate Basico (15 min)

### Paso 1.1: Revisar el manifiesto inicial

Revisa el archivo `recreate-v1.yaml` antes de aplicarlo:

```bash
cat recreate-v1.yaml
```

Puntos clave del manifiesto:
- **3 replicas** de nginx:1.19-alpine
- **Estrategia Recreate**: `strategy.type: Recreate`
- Sin `rollingUpdate`, sin `maxSurge`, sin `maxUnavailable`
- **readinessProbe** para verificar que los Pods respondan antes de marcarlos Ready
- **change-cause** como anotacion para el historial de revisiones

### Paso 1.2: Aplicar Deployment inicial

```bash
kubectl apply -f recreate-v1.yaml
```

**Output esperado**:
```
deployment.apps/nginx-recreate created
```

### Paso 1.3: Verificar estado inicial

```bash
# Ver Deployment
kubectl get deployment nginx-recreate

# Ver ReplicaSet creado
kubectl get replicaset -l app=nginx-recreate

# Ver Pods con label de version
kubectl get pods -l app=nginx-recreate -L version
```

**Output esperado**:
```
NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
nginx-recreate                    3/3     3            3           30s

NAME                               DESIRED   CURRENT   READY   AGE
nginx-recreate-7d4f8c6b9f          3         3         3       30s

NAME                                   READY   STATUS    RESTARTS   AGE   VERSION
nginx-recreate-7d4f8c6b9f-abc          1/1     Running   0          30s   v1.0
nginx-recreate-7d4f8c6b9f-def          1/1     Running   0          30s   v1.0
nginx-recreate-7d4f8c6b9f-ghi          1/1     Running   0          30s   v1.0
```

### Paso 1.4: Verificar estrategia configurada

```bash
kubectl get deployment nginx-recreate -o jsonpath='{.spec.strategy.type}'
echo
```

**Output esperado**:
```
Recreate
```

### Paso 1.5: Comparar diferencias entre v1 y v2

Antes de aplicar el update, revisa los cambios entre ambos archivos:

```bash
diff recreate-v1.yaml recreate-v2.yaml
```

**Output esperado** (los cambios clave):
```
< kubernetes.io/change-cause: "v1.0 - Deploy inicial con nginx 1.19 (Recreate)"
> kubernetes.io/change-cause: "v2.0 - Update a nginx 1.20 (Recreate)"
<     version: "v1.0"
>     version: "v2.0"
<         image: nginx:1.19-alpine
>         image: nginx:1.20-alpine
```

### Paso 1.6: Observar el comportamiento Recreate en tiempo real

Abre dos terminales para monitorear el update simultaneamente.

**Terminal 1** (monitoreo de Pods):
```bash
kubectl get pods -l app=nginx-recreate -w
```

**Terminal 2** (aplicar actualizacion):
```bash
kubectl apply -f recreate-v2.yaml
```

**Output esperado en Terminal 2**:
```
deployment.apps/nginx-recreate configured
```

**Observacion en Terminal 1** (comportamiento critico):
```
nginx-recreate-7d4f8c6b9f-abc    1/1     Running       0     2m
nginx-recreate-7d4f8c6b9f-def    1/1     Running       0     2m
nginx-recreate-7d4f8c6b9f-ghi    1/1     Running       0     2m
nginx-recreate-7d4f8c6b9f-abc    1/1     Terminating   0     2m   <- TODOS terminan
nginx-recreate-7d4f8c6b9f-def    1/1     Terminating   0     2m   <- simultaneamente
nginx-recreate-7d4f8c6b9f-ghi    1/1     Terminating   0     2m   <- DOWNTIME AQUI
nginx-recreate-7d4f8c6b9f-abc    0/1     Terminating   0     2m
nginx-recreate-7d4f8c6b9f-def    0/1     Terminating   0     2m
nginx-recreate-7d4f8c6b9f-ghi    0/1     Terminating   0     2m
nginx-recreate-8f5c9d7a8g-pqr    0/1     Pending       0     0s   <- Nuevos crean DESPUES
nginx-recreate-8f5c9d7a8g-stu    0/1     Pending       0     0s
nginx-recreate-8f5c9d7a8g-vwx    0/1     Pending       0     0s
nginx-recreate-8f5c9d7a8g-pqr    0/1     ContainerCreating   0   0s
nginx-recreate-8f5c9d7a8g-pqr    1/1     Running       0     5s
nginx-recreate-8f5c9d7a8g-stu    1/1     Running       0     6s
nginx-recreate-8f5c9d7a8g-vwx    1/1     Running       0     6s
```

**Explicacion del comportamiento**:
1. Los 3 Pods v1.0 entran en estado `Terminating` simultaneamente
2. Hay un periodo donde **0 Pods** estan disponibles (downtime completo)
3. Solo cuando todos terminaron, Kubernetes crea los 3 Pods v2.0 nuevos

### Paso 1.7: Verificar la nueva version

```bash
# Verificar imagen en los Pods
kubectl get pods -l app=nginx-recreate -o jsonpath='{.items[0].spec.containers[0].image}'
echo

# Verificar label de version
kubectl get pods -l app=nginx-recreate -L version
```

**Output esperado**:
```
nginx:1.20-alpine

NAME                                   READY   STATUS    RESTARTS   AGE   VERSION
nginx-recreate-8f5c9d7a8g-pqr          1/1     Running   0          30s   v2.0
nginx-recreate-8f5c9d7a8g-stu          1/1     Running   0          30s   v2.0
nginx-recreate-8f5c9d7a8g-vwx          1/1     Running   0          30s   v2.0
```

### Paso 1.8: Ver historial de revisiones

```bash
kubectl rollout history deployment nginx-recreate
```

**Output esperado**:
```
REVISION  CHANGE-CAUSE
1         v1.0 - Deploy inicial con nginx 1.19 (Recreate)
2         v2.0 - Update a nginx 1.20 (Recreate)
```

### Verificacion del Ejercicio 1

**Pregunta**: Durante el update con Recreate, cuantos Pods estuvieron disponibles en el momento de downtime?

<details>
<summary>Respuesta</summary>
0 Pods. Con la estrategia Recreate todos los Pods antiguos se eliminan antes de crear los nuevos. No hay solapamiento entre versiones, lo que genera downtime completo durante la transicion.
</details>

**Pregunta**: Cuantos ReplicaSets existen despues del update?

<details>
<summary>Respuesta</summary>

```bash
kubectl get replicaset -l app=nginx-recreate
```

2 ReplicaSets: el antiguo (0 replicas) y el nuevo (3 replicas). El comportamiento final en numero de ReplicaSets es identico a RollingUpdate; la diferencia es el PROCESO de transicion, no el resultado.
</details>

---

## Ejercicio 2: Comparacion con RollingUpdate (15 min)

### Paso 2.1: Revisar el manifiesto comparativo

```bash
cat rolling-compare-v1.yaml
```

Puntos clave:
- Mismo `nginx:1.19-alpine` y mismas 3 replicas que el Deployment Recreate
- Estrategia `RollingUpdate` con `maxSurge: 1` y `maxUnavailable: 1`
- Compara las secciones `strategy:` de ambos manifiestos:

```bash
grep -A 6 'strategy:' recreate-v1.yaml
echo "---"
grep -A 6 'strategy:' rolling-compare-v1.yaml
```

**Output esperado**:
```
  strategy:
    type: Recreate    # Termina todos los Pods antes de crear nuevos
---
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
```

### Paso 2.2: Aplicar el Deployment comparativo

```bash
kubectl apply -f rolling-compare-v1.yaml
kubectl rollout status deployment nginx-rolling
```

**Output esperado**:
```
deployment "nginx-rolling" successfully rolled out
```

### Paso 2.3: Verificar ambos Deployments activos

```bash
kubectl get deployments
```

**Output esperado**:
```
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
nginx-recreate   3/3     3            3           5m
nginx-rolling    3/3     3            3           30s
```

### Paso 2.4: Comparar diferencias entre versiones del Deployment rolling

```bash
diff rolling-compare-v1.yaml rolling-compare-v2.yaml
```

**Output esperado**:
```
< kubernetes.io/change-cause: "v1.0 - Deploy comparativo con RollingUpdate"
> kubernetes.io/change-cause: "v2.0 - Update a nginx 1.20 (RollingUpdate)"
<     version: "v1.0"
>     version: "v2.0"
<         image: nginx:1.19-alpine
>         image: nginx:1.20-alpine
```

### Paso 2.5: Observar RollingUpdate en tiempo real

**Terminal 1** (monitoreo de Pods rolling):
```bash
kubectl get pods -l app=nginx-rolling -w
```

**Terminal 2** (aplicar actualizacion):
```bash
kubectl apply -f rolling-compare-v2.yaml
```

**Observacion en Terminal 1** (comportamiento gradual):
```
nginx-rolling-7d4f8c6b9f-abc    1/1     Running       0     2m
nginx-rolling-7d4f8c6b9f-def    1/1     Running       0     2m
nginx-rolling-7d4f8c6b9f-ghi    1/1     Running       0     2m
nginx-rolling-8f5c9d7a8g-pqr    0/1     Pending       0     0s   <- 1 nuevo Pod
nginx-rolling-8f5c9d7a8g-pqr    0/1     ContainerCreating   0   0s
nginx-rolling-8f5c9d7a8g-pqr    1/1     Running       0     5s   <- Nuevo Ready
nginx-rolling-7d4f8c6b9f-abc    1/1     Terminating   0     2m   <- 1 viejo termina
nginx-rolling-8f5c9d7a8g-stu    0/1     Pending       0     0s   <- Siguiente nuevo
nginx-rolling-7d4f8c6b9f-def    1/1     Terminating   0     2m
nginx-rolling-8f5c9d7a8g-stu    1/1     Running       0     5s
nginx-rolling-7d4f8c6b9f-ghi    1/1     Terminating   0     2m
nginx-rolling-8f5c9d7a8g-vwx    0/1     Pending       0     0s
nginx-rolling-8f5c9d7a8g-vwx    1/1     Running       0     5s
```

**Diferencias clave observadas**:

| Aspecto | Recreate | RollingUpdate |
|---------|----------|---------------|
| Pods en 0 disponibles | Si (downtime) | Nunca (siempre hay al menos 2) |
| Versiones simultaneas | No (solo una a la vez) | Si (v1 y v2 coexisten brevemente) |
| Velocidad de update | Mas rapido | Mas lento (gradual) |
| Uso de recursos extra | No | Si (hasta maxSurge extra) |

### Verificacion del Ejercicio 2

**Pregunta**: Durante el update con RollingUpdate, cuantos Pods estuvieron disponibles en el momento de menor disponibilidad?

<details>
<summary>Respuesta</summary>
Minimo 2 Pods (3 deseados - 1 de maxUnavailable). Con maxUnavailable: 1, Kubernetes garantiza que al menos 2 Pods esten disponibles en todo momento durante el update.
</details>

---

## Ejercicio 3: Monitoreo en Tiempo Real (10 min)

Este ejercicio usa comandos de monitoreo avanzados para capturar el comportamiento de Recreate.

### Paso 3.1: Monitorear con watch

Primero, restaura el Deployment recreate a v1 para poder observar el update desde el inicio:

```bash
kubectl apply -f recreate-v1.yaml
kubectl rollout status deployment nginx-recreate
```

### Paso 3.2: Abrir monitor continuo

**Terminal 1** (watch automatico cada 2 segundos):
```bash
watch -n 2 kubectl get pods -l app=nginx-recreate -L version
```

**Terminal 2** (aplicar update):
```bash
kubectl apply -f recreate-v2.yaml
```

**Lo que veras en Terminal 1** (secuencia de estados):

Estado 1 - Antes del update:
```
NAME                                   READY   STATUS    RESTARTS   AGE   VERSION
nginx-recreate-7d4f8c6b9f-abc          1/1     Running   0          1m    v1.0
nginx-recreate-7d4f8c6b9f-def          1/1     Running   0          1m    v1.0
nginx-recreate-7d4f8c6b9f-ghi          1/1     Running   0          1m    v1.0
```

Estado 2 - Durante downtime:
```
NAME                                   READY   STATUS        RESTARTS   AGE   VERSION
nginx-recreate-7d4f8c6b9f-abc          0/1     Terminating   0          1m    v1.0
nginx-recreate-7d4f8c6b9f-def          0/1     Terminating   0          1m    v1.0
nginx-recreate-7d4f8c6b9f-ghi          0/1     Terminating   0          1m    v1.0
```

Estado 3 - Despues del update:
```
NAME                                   READY   STATUS    RESTARTS   AGE   VERSION
nginx-recreate-8f5c9d7a8g-pqr          1/1     Running   0          10s   v2.0
nginx-recreate-8f5c9d7a8g-stu          1/1     Running   0          10s   v2.0
nginx-recreate-8f5c9d7a8g-vwx          1/1     Running   0          10s   v2.0
```

### Paso 3.3: Revisar eventos del rollout

```bash
kubectl describe deployment nginx-recreate | grep -A 15 "Events:"
```

**Output esperado**:
```
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  5m    deployment-controller  Scaled up replica set nginx-recreate-7d4f8c6b9f to 3
  Normal  ScalingReplicaSet  2m    deployment-controller  Scaled down replica set nginx-recreate-7d4f8c6b9f to 0 from 3
  Normal  ScalingReplicaSet  2m    deployment-controller  Scaled up replica set nginx-recreate-8f5c9d7a8g to 3 from 0
```

**Nota importante**: Los mensajes "Scaled down... to 0" y "Scaled up... to 3 from 0" confirman el comportamiento Recreate: primero escala a CERO y luego crea todos los nuevos.

### Paso 3.4: Monitorear rollout status

```bash
# Aplicar v1 de nuevo para preparar siguiente observacion
kubectl apply -f recreate-v1.yaml
kubectl rollout status deployment nginx-recreate

# Aplicar v2 y monitorear el status
kubectl apply -f recreate-v2.yaml
kubectl rollout status deployment nginx-recreate
```

**Output esperado de rollout status**:
```
Waiting for deployment "nginx-recreate" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "nginx-recreate" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "nginx-recreate" rollout to finish: 2 of 3 updated replicas are available...
deployment "nginx-recreate" successfully rolled out
```

### Verificacion del Ejercicio 3

**Pregunta**: En la salida de `kubectl describe deployment`, que dos eventos de ScalingReplicaSet confirman que se uso Recreate y no RollingUpdate?

<details>
<summary>Respuesta</summary>
Los eventos que confirman Recreate son:
1. "Scaled down replica set ... to 0 from 3" — el ReplicaSet antiguo se escala a CERO antes de crear el nuevo
2. "Scaled up replica set ... to 3 from 0" — el ReplicaSet nuevo se crea desde CERO

En RollingUpdate los eventos serian incrementales: "to 0 from 1", "to 4 from 5", etc., nunca bajando directamente a 0.
</details>

---

## Ejercicio 4: Analisis del Downtime (10 min)

### Paso 4.1: Verificar la configuracion de estrategia

```bash
# Ver la seccion strategy completa en YAML
kubectl get deployment nginx-recreate -o yaml | grep -A 5 "strategy:"
```

**Output esperado**:
```yaml
  strategy:
    type: Recreate
```

Comparar con el Deployment rolling:

```bash
kubectl get deployment nginx-rolling -o yaml | grep -A 8 "strategy:"
```

**Output esperado**:
```yaml
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
```

### Paso 4.2: Verificar historial de ambos Deployments

```bash
# Historial de Recreate
echo "=== Historial nginx-recreate ==="
kubectl rollout history deployment nginx-recreate

# Historial de RollingUpdate
echo "=== Historial nginx-rolling ==="
kubectl rollout history deployment nginx-rolling
```

**Output esperado**:
```
=== Historial nginx-recreate ===
REVISION  CHANGE-CAUSE
1         v1.0 - Deploy inicial con nginx 1.19 (Recreate)
2         v2.0 - Update a nginx 1.20 (Recreate)
3         v1.0 - Deploy inicial con nginx 1.19 (Recreate)
4         v2.0 - Update a nginx 1.20 (Recreate)

=== Historial nginx-rolling ===
REVISION  CHANGE-CAUSE
1         v1.0 - Deploy comparativo con RollingUpdate
2         v2.0 - Update a nginx 1.20 (RollingUpdate)
```

### Paso 4.3: Contar ReplicaSets de cada Deployment

```bash
echo "=== ReplicaSets de nginx-recreate ==="
kubectl get replicaset -l app=nginx-recreate

echo "=== ReplicaSets de nginx-rolling ==="
kubectl get replicaset -l app=nginx-rolling
```

**Output esperado**:
```
=== ReplicaSets de nginx-recreate ===
NAME                           DESIRED   CURRENT   READY   AGE
nginx-recreate-7d4f8c6b9f      0         0         0       8m
nginx-recreate-8f5c9d7a8g      0         0         0       5m
nginx-recreate-9a6b0e1h2i      0         0         0       3m
nginx-recreate-0b7c1f2j3k      3         3         3       30s

=== ReplicaSets de nginx-rolling ===
NAME                          DESIRED   CURRENT   READY   AGE
nginx-rolling-7d4f8c6b9f      0         0         0       6m
nginx-rolling-8f5c9d7a8g      3         3         3       2m
```

### Paso 4.4: Ver detalle de una revision especifica

```bash
kubectl rollout history deployment nginx-recreate --revision=1
```

**Output esperado**:
```
deployment.apps/nginx-recreate with revision #1
Pod Template:
  Labels:	app=nginx-recreate
		pod-template-hash=7d4f8c6b9f
		version=v1.0
  Annotations:	kubernetes.io/change-cause: v1.0 - Deploy inicial con nginx 1.19 (Recreate)
  Containers:
   nginx:
    Image:	nginx:1.19-alpine
    Port:	80/TCP
    Host Port:	0/TCP
    ...
```

### Paso 4.5: Comparar condiciones de ambos Deployments

```bash
echo "=== Condiciones nginx-recreate ==="
kubectl get deployment nginx-recreate -o jsonpath='{.status.conditions[*].type}' && echo

echo "=== Condiciones nginx-rolling ==="
kubectl get deployment nginx-rolling -o jsonpath='{.status.conditions[*].type}' && echo
```

**Output esperado**:
```
=== Condiciones nginx-recreate ===
Progressing Available
=== Condiciones nginx-rolling ===
Progressing Available
```

Ambas estrategias resultan en Deployments en estado `Available`. La diferencia es el proceso de actualizacion, no el estado final.

### Verificacion del Ejercicio 4

**Pregunta**: En que escenarios de produccion justificarias el uso de Recreate a pesar del downtime?

<details>
<summary>Respuesta</summary>
Escenarios validos en produccion:
1. La aplicacion usa un ORM que ejecuta migraciones de base de datos al iniciar, y las migraciones no son compatibles con la version anterior
2. La aplicacion escribe en un archivo o directorio que solo puede ser accedido por una instancia a la vez (PersistentVolume con accessMode ReadWriteOnce)
3. La aplicacion mantiene estado en memoria local que no puede compartirse entre versiones (cache local incompatible)
4. Sistema de procesamiento de cola donde tener dos versiones consumiendo mensajes causaria procesamiento duplicado o errores de formato

En todos estos casos, el downtime controlado con Recreate es preferible a los errores impredecibles de correr dos versiones en paralelo.
</details>

---

## Limpieza

Ejecuta el script de limpieza incluido:

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete deployment nginx-recreate nginx-rolling -n lab-recreate
kubectl delete namespace lab-recreate
kubectl config set-context --current --namespace=default
```

---

## Resumen

En este laboratorio aprendiste:

- **Estrategia Recreate**: Termina TODOS los Pods antes de crear nuevos, produciendo downtime completo
- **Enfoque declarativo**: Todas las actualizaciones se gestionaron mediante archivos YAML versionados (v1 -> v2)
- **Comparacion directa**: Recreate vs RollingUpdate observada en tiempo real con dos Deployments paralelos
- **Monitoreo**: Uso de `kubectl get pods -w`, `watch`, `kubectl rollout status` y `kubectl describe` para analizar updates
- **Eventos**: Los eventos ScalingReplicaSet confirman el comportamiento "scale to 0, then scale up" de Recreate
- **Casos de uso**: Recreate es correcto cuando la aplicacion no puede correr multiples versiones simultaneas
- **diff**: Comparacion de manifiestos antes de aplicar cambios para entender que va a cambiar

---

## Solucion de Problemas

### Los Pods no terminan rapido

Si los Pods tardan mucho en terminar, puede haber un `terminationGracePeriodSeconds` alto configurado.
Verifica:

```bash
kubectl get deployment nginx-recreate -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}'
```

Por defecto es 30 segundos. Puedes reducirlo para pruebas, pero en produccion mantener el valor apropiado para que la aplicacion cierre conexiones correctamente.

### El rollout status se queda esperando

Si `kubectl rollout status` no termina, verifica que los nuevos Pods esten pasando el readinessProbe:

```bash
kubectl describe pod -l app=nginx-recreate | grep -A 10 "Events:"
```

Busca errores de imagen (ImagePullBackOff), recursos insuficientes (Insufficient memory/cpu), o fallas en el readinessProbe.

### No se ve el downtime durante el watch

El downtime con Recreate puede ser muy breve (menos de 2 segundos) si la imagen ya esta cacheada localmente. Para ver el estado de 0 Pods mas claramente, usa `-w` (watch continuo) en lugar de `watch -n 2`:

```bash
kubectl get pods -l app=nginx-recreate -w
```

---

## Recursos Relacionados

- [Laboratorio 1: Crear Deployments](../lab-01-crear-deployments/)
- [Laboratorio 2: Rolling Updates](../lab-02-rolling-updates/)
- [Laboratorio 3: Rollback y Versiones](../lab-03-rollback/)
- [Ejemplos de Deployments](../../ejemplos/)
- [README del modulo](../../README.md)

---

**Excelente trabajo!**
Has completado el Lab 04. Continua con los ejemplos avanzados del modulo para profundizar en estrategias de despliegue.
