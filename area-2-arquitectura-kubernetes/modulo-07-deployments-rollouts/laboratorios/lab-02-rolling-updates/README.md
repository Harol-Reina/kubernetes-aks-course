# Laboratorio 2: Rolling Updates y Estrategias de Despliegue

## 📋 Información del Laboratorio

- **Duración estimada**: 50 minutos
- **Nivel**: Intermedio
- **Requisitos**: Laboratorio 1 completado
- **Namespace**: `lab-rolling-updates`

## 🎯 Objetivos

Al completar este laboratorio, serás capaz de:

1. Entender el proceso de rolling update en detalle
2. Controlar el comportamiento con `maxSurge` y `maxUnavailable`
3. Comparar estrategias RollingUpdate vs Recreate
4. Monitorear el progreso de un rollout
5. Usar anotaciones `change-cause` para historial descriptivo
6. Pausar y reanudar rollouts
7. Gestionar actualizaciones de forma declarativa con archivos YAML

## 📚 Prerrequisitos

- Laboratorio 1 completado
- Conocimiento de Deployments básicos
- Cluster de Kubernetes funcional

## 📁 Archivos YAML del Laboratorio

Este laboratorio utiliza un enfoque **100% declarativo**. Todas las operaciones se realizan mediante archivos YAML:

| Archivo | Ejercicio | Descripción |
|---------|-----------|-------------|
| `rolling-demo-v1.yaml` | 1 | Deployment inicial con nginx:1.20 |
| `rolling-demo-v2.yaml` | 1 | Actualización a nginx:1.21 |
| `rolling-ha-v1.yaml` | 2 | Alta disponibilidad (maxUnavailable: 0) |
| `rolling-ha-v2.yaml` | 2 | Update HA a nginx:1.21 |
| `rolling-fast-v1.yaml` | 2 | Actualización rápida (maxUnavailable: 2) |
| `rolling-fast-v2.yaml` | 2 | Update rápido a nginx:1.22 |
| `recreate-demo-v1.yaml` | 3 | Estrategia Recreate con nginx:1.20 |
| `recreate-demo-v2.yaml` | 3 | Update Recreate a nginx:1.21 |
| `pause-demo-v1.yaml` | 4 | Demo pause/resume inicial |
| `pause-demo-v2.yaml` | 4 | Múltiples cambios en un rollout |
| `challenge-app-v1.yaml` | Desafío | Challenge deployment inicial |
| `challenge-app-v2.yaml` | Desafío | Challenge actualizado |

## 🔧 Preparación del Entorno

```bash
# Crear namespace
kubectl create namespace lab-rolling-updates
kubectl config set-context --current --namespace=lab-rolling-updates

# Verificar
kubectl config view --minify | grep namespace:
```

**Output esperado**:
```
    namespace: lab-rolling-updates
```

---

## Ejercicio 1: Rolling Update Básico (10 min)

### Paso 1.1: Revisar el manifiesto inicial

Revisa el archivo `rolling-demo-v1.yaml` antes de aplicarlo:

```bash
cat rolling-demo-v1.yaml
```

Puntos clave del manifiesto:
- **5 réplicas** de nginx:1.20-alpine
- **Estrategia RollingUpdate** con `maxSurge: 1` y `maxUnavailable: 1`
- **readinessProbe** para verificar que los Pods estén listos antes de aceptar tráfico
- **change-cause** como anotación para el historial de revisiones

### Paso 1.2: Aplicar Deployment inicial

```bash
kubectl apply -f rolling-demo-v1.yaml
```

**Output esperado**:
```
deployment.apps/rolling-demo created
```

### Paso 1.3: Verificar estado inicial

```bash
# Ver Deployment
kubectl get deployment rolling-demo

# Ver ReplicaSet
kubectl get replicaset -l app=rolling-demo

# Ver Pods con label de versión
kubectl get pods -L version
```

**Output esperado**:
```
NAME                           READY   STATUS    RESTARTS   AGE   VERSION
rolling-demo-7d4f8c6b9f-abc    1/1     Running   0          30s   v1.0
rolling-demo-7d4f8c6b9f-def    1/1     Running   0          30s   v1.0
rolling-demo-7d4f8c6b9f-ghi    1/1     Running   0          30s   v1.0
rolling-demo-7d4f8c6b9f-jkl    1/1     Running   0          30s   v1.0
rolling-demo-7d4f8c6b9f-mno    1/1     Running   0          30s   v1.0
```

### Paso 1.4: Comparar diferencias entre v1 y v2

Antes de aplicar el update, revisa las diferencias entre ambos archivos:

```bash
diff rolling-demo-v1.yaml rolling-demo-v2.yaml
```

**Output esperado** (los cambios clave):
```
< kubernetes.io/change-cause: "v1.0 - Deploy inicial con nginx 1.20"
> kubernetes.io/change-cause: "v2.0 - Actualizar nginx a 1.21"
<     version: "v1.0"
>     version: "v2.0"
<     image: nginx:1.20-alpine
>     image: nginx:1.21-alpine
```

### Paso 1.5: Realizar rolling update

**Terminal 1** (monitoreo):
```bash
kubectl get pods -l app=rolling-demo -w
```

**Terminal 2** (actualización):
```bash
kubectl apply -f rolling-demo-v2.yaml
```

**Output esperado en Terminal 2**:
```
deployment.apps/rolling-demo configured
```

**Observación en Terminal 1**:
```
rolling-demo-7d4f8c6b9f-abc    1/1     Running       0     2m
rolling-demo-8f5c9d7a8g-pqr    0/1     Pending       0     0s   <- Nuevo Pod creado
rolling-demo-8f5c9d7a8g-pqr    0/1     ContainerCreating   0     0s
rolling-demo-8f5c9d7a8g-pqr    0/1     Running       0     2s
rolling-demo-8f5c9d7a8g-pqr    1/1     Running       0     5s   <- Nuevo Pod Ready
rolling-demo-7d4f8c6b9f-abc    1/1     Terminating   0     2m   <- Viejo Pod terminando
rolling-demo-8f5c9d7a8g-stu    0/1     Pending       0     0s   <- Siguiente nuevo Pod
...
```

### Paso 1.6: Ver historial de revisiones

```bash
kubectl rollout history deployment rolling-demo
```

**Output esperado**:
```
REVISION  CHANGE-CAUSE
1         v1.0 - Deploy inicial con nginx 1.20
2         v2.0 - Actualizar nginx a 1.21
```

### Paso 1.7: Verificar la nueva versión

```bash
# Verificar imagen en los Pods
kubectl get pods -l app=rolling-demo -o jsonpath='{.items[0].spec.containers[0].image}'
echo

# Verificar label de versión
kubectl get pods -l app=rolling-demo -L version
```

**Output esperado**:
```
nginx:1.21-alpine
```

### ✅ Verificación

**Pregunta**: ¿Cuántos Pods estuvieron corriendo simultáneamente durante el update?

<details>
<summary>Respuesta</summary>
Máximo 6 Pods (5 deseados + 1 de maxSurge)
</details>

**Pregunta**: ¿Cuál fue el mínimo de Pods disponibles?

<details>
<summary>Respuesta</summary>
Mínimo 4 Pods (5 deseados - 1 de maxUnavailable)
</details>

---

## Ejercicio 2: Controlar maxSurge y maxUnavailable (15 min)

### Paso 2.1: Caso A - Alta disponibilidad (maxUnavailable: 0)

Revisa el manifiesto de alta disponibilidad:

```bash
cat rolling-ha-v1.yaml
```

Puntos clave:
- `maxSurge: 1` → Permite hasta 5 Pods (4 + 1)
- `maxUnavailable: 0` → **NUNCA** baja de 4 Pods disponibles

```bash
kubectl apply -f rolling-ha-v1.yaml

# Esperar a que esté ready
kubectl rollout status deployment rolling-ha
```

**Output esperado**:
```
deployment "rolling-ha" successfully rolled out
```

### Paso 2.2: Actualizar con maxUnavailable: 0

**Terminal 1**:
```bash
kubectl get pods -l app=rolling-ha -w
```

**Terminal 2**:
```bash
kubectl apply -f rolling-ha-v2.yaml
```

**Observación**:
- Primero crea 1 Pod nuevo (maxSurge: 1)
- Espera a que esté Ready
- LUEGO termina 1 Pod viejo
- Repite hasta terminar
- Siempre hay 4 Pods disponibles

**Cálculo**:
```
maxSurge: 1       → Permite hasta 5 Pods (4 + 1)
maxUnavailable: 0 → Mínimo 4 Pods siempre
```

### Paso 2.3: Caso B - Actualización rápida (maxUnavailable: 2)

Revisa las diferencias de estrategia entre ambos enfoques:

```bash
# Comparar las estrategias
diff <(grep -A5 'strategy:' rolling-ha-v1.yaml) <(grep -A5 'strategy:' rolling-fast-v1.yaml)
```

Aplica el Deployment rápido:

```bash
kubectl apply -f rolling-fast-v1.yaml
kubectl rollout status deployment rolling-fast
```

### Paso 2.4: Actualizar con parámetros agresivos

**Terminal 1**:
```bash
kubectl get pods -l app=rolling-fast -w
```

**Terminal 2**:
```bash
kubectl apply -f rolling-fast-v2.yaml
```

**Observación**:
- Crea hasta 2 Pods nuevos simultáneamente
- Puede tener hasta 2 Pods down
- Actualización MUCHO más rápida
- Trade-off: Menos disponibilidad durante update

**Cálculo**:
```
maxSurge: 2       → Permite hasta 8 Pods (6 + 2)
maxUnavailable: 2 → Mínimo 4 Pods (6 - 2)
```

### Paso 2.5: Comparar tiempos

```bash
# Ver eventos del rollout HA (lento)
kubectl describe deployment rolling-ha | grep -A 5 Events

# Ver eventos del rollout rápido
kubectl describe deployment rolling-fast | grep -A 5 Events
```

**Comparación**:
| Deployment | maxSurge | maxUnavailable | Disponibilidad | Velocidad |
|------------|----------|----------------|----------------|-----------|
| rolling-ha | 1 | 0 | 100% (4/4) | Lento |
| rolling-fast | 2 | 2 | 67% (4/6) | Rápido |

### ✅ Verificación

**Pregunta**: ¿Cuándo usarías `maxUnavailable: 0`?

<details>
<summary>Respuesta</summary>
Producción con alta disponibilidad crítica, donde NO puedes tolerar reducción de capacidad.
</details>

**Pregunta**: ¿Cuándo usarías `maxUnavailable: 2`?

<details>
<summary>Respuesta</summary>
Desarrollo/staging, o producción con tolerancia a downtime parcial, priorizando velocidad.
</details>

---

## Ejercicio 3: Estrategia Recreate (10 min)

### Paso 3.1: Revisar el manifiesto Recreate

```bash
cat recreate-demo-v1.yaml
```

Punto clave: `strategy.type: Recreate` — no hay `rollingUpdate`, no hay `maxSurge`/`maxUnavailable`.

### Paso 3.2: Crear Deployment con estrategia Recreate

```bash
kubectl apply -f recreate-demo-v1.yaml
kubectl rollout status deployment recreate-demo
```

### Paso 3.3: Comparar diferencias antes de actualizar

```bash
diff recreate-demo-v1.yaml recreate-demo-v2.yaml
```

### Paso 3.4: Actualizar con Recreate

**Terminal 1**:
```bash
kubectl get pods -l app=recreate-demo -w
```

**Terminal 2**:
```bash
kubectl apply -f recreate-demo-v2.yaml
```

**Observación en Terminal 1**:
```
recreate-demo-abc   1/1     Running       0     1m
recreate-demo-def   1/1     Running       0     1m
recreate-demo-ghi   1/1     Running       0     1m
recreate-demo-jkl   1/1     Running       0     1m
recreate-demo-abc   1/1     Terminating   0     1m  <- TODOS terminan
recreate-demo-def   1/1     Terminating   0     1m
recreate-demo-ghi   1/1     Terminating   0     1m
recreate-demo-jkl   1/1     Terminating   0     1m
recreate-demo-abc   0/1     Terminating   0     1m
...
recreate-demo-pqr   0/1     Pending       0     0s  <- Nuevos Pods crean DESPUÉS
recreate-demo-stu   0/1     Pending       0     0s
recreate-demo-vwx   0/1     Pending       0     0s
recreate-demo-yza   0/1     Pending       0     0s
recreate-demo-pqr   0/1     ContainerCreating   0     0s
...
```

**Explicación**:
1. TODOS los Pods viejos se eliminan primero
2. Hay un período de **DOWNTIME COMPLETO** (0 Pods)
3. Luego se crean TODOS los Pods nuevos
4. No hay Pods de versiones diferentes corriendo juntas

### Paso 3.5: Verificar downtime

```bash
kubectl describe deployment recreate-demo | grep -A 10 Events
```

**Output esperado**:
```
Events:
  Type    Reason             Message
  ----    ------             -------
  Normal  ScalingReplicaSet  Scaled down replica set recreate-demo-old to 0
  Normal  ScalingReplicaSet  Scaled up replica set recreate-demo-new to 4
```

**Nota**: Hay un gap temporal entre el scale down y scale up.

### Paso 3.6: Cuándo usar Recreate

**Casos de uso válidos**:
- Aplicación NO soporta múltiples versiones simultáneas
- Migración de base de datos incompatible
- Cambios de schema que requieren downtime
- Desarrollo/testing (no producción)

**NO usar Recreate si**:
- Necesitas alta disponibilidad
- Puedes hacer rolling updates
- Estás en producción

### ✅ Verificación

Ejecuta:
```bash
# Contar ReplicaSets
kubectl get replicaset -l app=recreate-demo
```

**Pregunta**: ¿Cuántos ReplicaSets hay?

<details>
<summary>Respuesta</summary>
2: El viejo (0 réplicas) y el nuevo (4 réplicas), igual que con RollingUpdate. La diferencia es el PROCESO de actualización, no el resultado final.
</details>

---

## Ejercicio 4: Pausar y Reanudar Rollouts (15 min)

### Paso 4.1: Crear Deployment para demo

Revisa el manifiesto con sus variables de entorno y recursos:

```bash
cat pause-demo-v1.yaml
```

```bash
kubectl apply -f pause-demo-v1.yaml
kubectl rollout status deployment pause-demo
```

### Paso 4.2: Pausar el Deployment

```bash
kubectl rollout pause deployment pause-demo
```

**Output**: `deployment.apps/pause-demo paused`

### Paso 4.3: Revisar los cambios de v2

Compara ambos archivos para ver los **4 cambios** que se aplicarán juntos:

```bash
diff pause-demo-v1.yaml pause-demo-v2.yaml
```

**Cambios en pause-demo-v2.yaml**:
1. **Imagen**: nginx:1.20-alpine → nginx:1.23-alpine
2. **Variable de entorno**: APP_VERSION v1.0 → v2.0
3. **Recursos**: requests y limits aumentados
4. **Réplicas**: 6 → 8

### Paso 4.4: Aplicar cambios mientras está pausado

```bash
kubectl apply -f pause-demo-v2.yaml
```

**Output**:
```
deployment.apps/pause-demo configured
```

### Paso 4.5: Verificar que NO se aplican cambios a los Pods

```bash
# Los Pods siguen con la versión anterior
kubectl get pods -l app=pause-demo -L version

# La spec del Deployment ya cambió
kubectl get deployment pause-demo -o jsonpath='{.spec.template.spec.containers[0].image}'
echo
```

**Output**: `nginx:1.23-alpine` (cambió en spec)

```bash
# Pero los Pods reales NO cambiaron
kubectl get pods -l app=pause-demo -o jsonpath='{.items[0].spec.containers[0].image}'
echo
```

**Output**: `nginx:1.20-alpine` (NO cambió en Pods)

**Explicación**: Los cambios están en el Deployment spec, pero NO se han propagado a los Pods porque el rollout está **pausado**.

### Paso 4.6: Reanudar el Deployment

**Terminal 1**:
```bash
kubectl get pods -l app=pause-demo -w
```

**Terminal 2**:
```bash
kubectl rollout resume deployment pause-demo
```

**Output**:
```
deployment.apps/pause-demo resumed
```

**Observación**:
- AHORA sí se inicia el rolling update
- TODOS los 4 cambios se aplican en UN solo rollout
- Más eficiente que 4 rollouts separados

### Paso 4.7: Verificar resultado

```bash
# Ver Pods finales (deben ser 8)
kubectl get pods -l app=pause-demo
```

**Output esperado**: 8 Pods (escalado de 6 a 8)

```bash
# Verificar imagen
kubectl get pods -l app=pause-demo -o jsonpath='{.items[0].spec.containers[0].image}'
echo
```

**Output**: `nginx:1.23-alpine`

```bash
# Verificar variable de entorno
kubectl exec deployment/pause-demo -- env | grep APP_VERSION
```

**Output**: `APP_VERSION=v2.0`

```bash
# Verificar recursos
kubectl get pods -l app=pause-demo -o jsonpath='{.items[0].spec.containers[0].resources}'
echo
```

**Output**: `{"limits":{"cpu":"500m","memory":"256Mi"},"requests":{"cpu":"200m","memory":"128Mi"}}`

### ✅ Verificación

**Pregunta**: ¿Cuántos rollouts se ejecutaron?

<details>
<summary>Respuesta</summary>
1 solo rollout (en lugar de 4 separados). Pause/Resume permite agrupar múltiples cambios declarados en el YAML y aplicarlos en una sola operación de rollout.
</details>

---

## 🎓 Desafío Final

Crea un Deployment que cumpla:

1. **Nombre**: `challenge-app`
2. **Réplicas**: 10
3. **Estrategia**: RollingUpdate
   - Garantía de alta disponibilidad (maxUnavailable: 0)
   - Permite hasta 3 Pods extra durante update
4. **Imagen inicial**: `nginx:1.21-alpine`
5. **Change-cause**: "v1.0 - Challenge deployment"
6. **Tarea**: Actualizar a `nginx:1.23-alpine` y verificar que NUNCA baja de 10 Pods disponibles

<details>
<summary>Solución</summary>

**Paso 1**: Aplicar la versión inicial:

```bash
kubectl apply -f challenge-app-v1.yaml
kubectl rollout status deployment challenge-app
```

**Paso 2**: Revisar las diferencias antes de actualizar:

```bash
diff challenge-app-v1.yaml challenge-app-v2.yaml
```

**Paso 3**: Monitorear y actualizar:

Terminal 1 (monitoreo):
```bash
kubectl get pods -l app=challenge-app -w
```

Terminal 2 (actualización):
```bash
kubectl apply -f challenge-app-v2.yaml
```

**Paso 4**: Verificar:

```bash
# Durante el update: máximo 13 Pods (10 + 3) y mínimo 10 Pods (10 - 0)
kubectl rollout status deployment challenge-app

# Verificar imagen final
kubectl get pods -l app=challenge-app -o jsonpath='{.items[0].spec.containers[0].image}'
echo
```

**Output esperado**: `nginx:1.23-alpine`

</details>

---

## 🧹 Limpieza

Ejecuta el script de limpieza incluido:

```bash
./cleanup.sh
```

O manualmente:

```bash
kubectl delete deployment --all -n lab-rolling-updates
kubectl delete namespace lab-rolling-updates
kubectl config set-context --current --namespace=default
```

---

## 📝 Resumen

En este laboratorio aprendiste:

- **Enfoque declarativo**: Todas las actualizaciones se gestionaron mediante archivos YAML versionados (v1 → v2)
- **Rolling Updates**: Proceso gradual de actualización aplicando un nuevo manifiesto YAML
- **maxSurge**: Pods extra permitidos durante update
- **maxUnavailable**: Pods que pueden estar down
- **Estrategia Recreate**: Downtime completo, todos los Pods reemplazados a la vez
- **Change-cause**: Anotaciones en YAML para historial descriptivo
- **Pause/Resume**: Pausar, aplicar un YAML con múltiples cambios, y reanudar en un rollout
- **Trade-offs**: Disponibilidad vs Velocidad de actualización
- **diff**: Comparar manifiestos antes de aplicar cambios

---

## 🔗 Recursos Relacionados

- [Laboratorio 1: Crear Deployments](../lab-01-crear-deployments/)
- [Laboratorio 3: Rollback y Versiones](../lab-03-rollback-versiones/)
- [Ejemplos de Rolling Updates](../../ejemplos/02-rolling-updates/)
- [README del módulo](../../README.md)

---

**¡Excelente trabajo! 🚀**
Continúa con [Laboratorio 3: Rollback y Versiones](../lab-03-rollback-versiones/).
